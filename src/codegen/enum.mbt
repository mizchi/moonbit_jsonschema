///|
/// extract enum values from oneOf schema with $tag const property
priv enum ParsedEnumerable {
  // { "prefixItems": [ { "const": "1" }, { ... } ] }
  // OneOfPrefixItems(Map[String, JsonSchema])

  // { "oneOf": [ { "const": "A", ... }, { "const": "B", ... } ] }
  OneOfTags(Map[String, JsonSchema])
  // { "oneOf": [ { "$ref": "#/definitions/A" }, { "$ref": "#/definitions/B" } ] }
  OneOfRefs(Array[JsonSchema])
}

///|
fn parse_enumerable_one_of(schema : JsonSchema) -> ParsedEnumerable? {
  guard schema is JsonSchema::OneOf(schemas) else { return None }
  guard schemas.get(0) is Some(first_schema) else { return None }
  // prefixItems case
  if first_schema
    is JsonSchema::Array(
      prefixItems=Some([JsonSchema::Const(String(_)), ..]),
      ..
    ) {
    let parsed : Map[String, JsonSchema] = {}
    for schema in schemas {
      match schema {
        JsonSchema::Array(
          prefixItems=Some([JsonSchema::Const(String(tag_value))]),
          ..
        ) => parsed.set(tag_value, JsonSchema::object(properties={}))
        JsonSchema::Array(
          prefixItems=Some([JsonSchema::Const(String(tag_value)), child_schema]),
          ..
        ) => parsed.set(tag_value, child_schema)
        _ => ()
      }
    }
    return Some(ParsedEnumerable::OneOfTags(parsed))
  }
  if first_schema is JsonSchema::Ref(_) {
    let refs : Array[JsonSchema] = []
    for schema in schemas {
      guard schema is JsonSchema::Ref(_) else { return None }
      refs.push(schema)
    }
    return Some(ParsedEnumerable::OneOfRefs(refs))
  }
  None
}

///|
fn render_enum(
  enum_name : String,
  parsed_enums : ParsedEnumerable,
  prefix~ : String,
  resolver~ : (String) -> JsonSchema?,
  pointer~ : JsonPointer,
) -> String {
  let logger = StringBuilder::new()
  logger.write_string(prefix)
  logger.write_string("enum \{enum_name} {\n")
  match parsed_enums {
    ParsedEnumerable::OneOfRefs(schemas) => {
      for subschema in schemas {
        guard subschema is JsonSchema::Ref(pointer) else { continue }
        if ref_to_identifier(pointer) is Some(key) {
          logger.write_string("  \{key}(\{key})\n")
        }
      }
      logger.write_string("} derive(Show, FromJson, ToJson)\n")
    }
    ParsedEnumerable::OneOfTags(enum_values) => {
      for tag_value, subschema in enum_values {
        if subschema is JsonSchema::Object(properties=Some(params), ..) {
          // no params
          if params.size() == 0 {
            logger.write_string("  \{tag_value}\n")
            continue
          }
          logger.write_string("  \{tag_value}(")
          let mut first = true
          for key, prop_schema in params {
            if !first {
              logger.write_string(", ")
            }
            first = false
            let subtype_code = generate_moonbit_property(
              prop_schema,
              resolver~,
              pointer=pointer.key(key),
            )
            logger.write_string("~\{key}: \{subtype_code}")
          }
          logger.write_string(")\n")

          // continue
        } else {
          // validate primitives only
          let subtype_code = generate_moonbit_property(
            subschema,
            resolver~,
            pointer=pointer.key(tag_value),
          )
          logger.write_string("  \{tag_value}(\{subtype_code})\n")
        }
      }
      // logger.write_string("}")
      logger.write_string("} derive(Show, FromJson, ToJson)\n")
    }
  }
  logger.to_string()
}

///|
fn ref_to_identifier(pointer : String) -> String? {
  if pointer.split("/").last() is Some(last) {
    last.to_string() |> Some
  } else {
    None
  }
}

///|
// test "$tag special case: oneOf to enum union types" {
//   let raw : Json = {
//     "oneOf": [
//       {
//         "type": "object",
//         "required": ["$tag", "x"],
//         "properties": { "$tag": { "const": "A" }, "a": { "type": "number" } },
//       },
//       {
//         "type": "object",
//         "properties": { "$tag": { "const": "B" }, "b": { "type": "string" } },
//       },
//     ],
//   }
//   let schema : JsonSchema = @json.from_json(raw)
//   let code = generate_moonbit_statement(schema, "MyEnum", resolver=fn(_) {
//     None
//   })
//   inspect(
//     // code,
//     code.unwrap(),
//     content=(
//       #|enum MyEnum {
//       #|  A(~a: Double)
//       #|  B(~b: String)
//       #|} derive(Show, FromJson(style="legacy"), ToJson(style="legacy"))
//       #|
//     ),
//   )
// }

///|
test "Parse [tagKey, {...}] for moonbit enum" {
  let raw : Json = {
    "definitions": { "Num": { "type": "integer" } },
    "oneOf": [
      {
        "type": "array",
        "prefixItems": [
          { "const": "A" },
          {
            "type": "object",
            "required": ["a"],
            "properties": { "a": { "type": "number" } },
          },
        ],
      },
      {
        "type": "array",
        "prefixItems": [{ "const": "B" }, { "type": "integer" }],
      },
      { "type": "array", "prefixItems": [{ "const": "C" }] },
      {
        "type": "array",
        "prefixItems": [{ "const": "X" }, { "$ref": "#/definitions/Num" }],
      },
    ],
  }
  // let schema : JsonSchema = @json.from_json(raw)
  let code = generate_moonbit(
    raw,
    [JsonPointer::Root],
    root_name="MyEnum",
    prefix="pub ",
  )
  inspect(
    // code,
    code.unwrap(),
    content=(
      #|// Generated by jsonschema
      #|
      #|// #
      #|pub enum MyEnum {
      #|  A(~a: Double)
      #|  B(Int)
      #|  C
      #|  X(Num)
      #|} derive(Show, FromJson, ToJson)
      #|
      #|// #/definitions/Num
      #|
      #|// skip by compile error #/definitions/Num
      #|

    ),
  )
}

///|
test "all refs in oneOf to enum union types" {
  let raw : Json = {
    "definitions": {
      "A": { "type": "object", "properties": { "a": { "type": "number" } } },
      "B": { "type": "object", "properties": { "b": { "type": "string" } } },
    },
    "oneOf": [{ "$ref": "#/definitions/A" }, { "$ref": "#/definitions/B" }],
  }
  // let schema : JsonSchema = @json.from_json(raw)
  let code = generate_moonbit(
    raw,
    [JsonPointer::Root],
    root_name="MyEnum",
    prefix="pub ",
  )
  inspect(
    // code,
    code.unwrap(),
    content=(
      #|// Generated by jsonschema
      #|
      #|// #
      #|pub enum MyEnum {
      #|  A(A)
      #|  B(B)
      #|} derive(Show, FromJson, ToJson)
      #|
      #|// #/definitions/A
      #|pub struct A {
      #|  a: Double?
      #|} derive(Show, FromJson, ToJson)
      #|
      #|// #/definitions/B
      #|pub struct B {
      #|  b: String?
      #|} derive(Show, FromJson, ToJson)
      #|
    ),
  )
}

///|
test "ref as root" {
  let raw : Json = {
    "definitions": {
      "A": { "type": "object", "properties": { "a": { "type": "number" } } },
      "B": { "type": "object", "properties": { "b": { "type": "string" } } },
      "Union": {
        "oneOf": [{ "$ref": "#/definitions/A" }, { "$ref": "#/definitions/B" }],
      },
    },
    "$ref": "#/definitions/Union",
  }
  // let schema : JsonSchema = @json.from_json(raw)
  let code = generate_moonbit(
    raw,
    [JsonPointer::Root],
    root_name="MyEnum",
    prefix="pub ",
  )
  inspect(
    code.unwrap(),
    // code.unwrap(),
    content=(
      #|// Generated by jsonschema
      #|
      #|// #
      #|pub enum MyEnum {
      #|  A(A)
      #|  B(B)
      #|} derive(Show, FromJson, ToJson)
      #|
      #|// #/definitions/A
      #|pub struct A {
      #|  a: Double?
      #|} derive(Show, FromJson, ToJson)
      #|
      #|// #/definitions/B
      #|pub struct B {
      #|  b: String?
      #|} derive(Show, FromJson, ToJson)
      #|
      #|// #/definitions/Union
      #|pub enum Union {
      #|  A(A)
      #|  B(B)
      #|} derive(Show, FromJson, ToJson)
      #|
    ),
  )
}
