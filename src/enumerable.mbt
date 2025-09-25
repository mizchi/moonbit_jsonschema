///|
pub(all) struct Enumerable {
  // variant tag
  tag : String
  // positional types
  positionals : Array[JsonSchema]?
  // named parameters
  params : Map[String, JsonSchema]?
} derive(Show, Eq)

///|
pub fn Enumerable::new(
  tag : String,
  positionals : Array[JsonSchema]?,
  // should be Object with properties
  params : Map[String, JsonSchema]?,
) -> Enumerable {
  { tag, positionals, params }
}

///|
pub fn Enumerable::parse_enumerable(schema : JsonSchema) -> Array[Enumerable]? {
  guard schema is JsonSchema::OneOf(schemas) else { return None }
  let parsed : Array[Enumerable] = []
  for schema in schemas {
    match schema {
      // {"const": "A"}
      JsonSchema::Const(String(tag_value)) =>
        parsed.push(Enumerable::new(tag_value, None, None))
      // [{"const": "A"}, { "type": "array", .. }]
      JsonSchema::Array(
        prefixItems=Some([JsonSchema::Const(String(tag_value))]),
        ..
      ) => parsed.push(Enumerable::new(tag_value, None, None))
      // [{"const": "A"}, ..]
      JsonSchema::Array(
        prefixItems=Some(
          [JsonSchema::Const(String(tag_value)), .. child_schemas]
        ),
        ..
      ) => {
        let matched = match child_schemas.to_array() {
          [] => { tag: tag_value, positionals: None, params: None }
          [.. positionals, Object(properties=Some(params), ..)] =>
            {
              tag: tag_value,
              positionals: positionals.to_array() |> Some,
              params: Some(params),
            }
          [.. positionals] =>
            {
              tag: tag_value,
              positionals: positionals.to_array() |> Some,
              params: None,
            }
        }
        parsed.push(matched)
      }
      _ => ()
    }
  }
  return Some(parsed)
  // }
  // None
}

///|
test "parse enumerable" {
  let enumerable : Json = {
    "oneOf": [
      { "const": "Single" },
      {
        "type": "array",
        "prefixItems": [
          { "const": "A" },
          { "type": "integer" },
          { "type": "string" },
        ],
      },
      // B(Number)
      {
        "type": "array",
        "prefixItems": [{ "const": "B" }, { "type": "number" }],
      },
      // C(~a: Int)
      {
        "type": "array",
        "prefixItems": [{ "const": "C" }, { "type": "integer" }],
      },
    ],
  }
  let schema : JsonSchema = @json.from_json(enumerable)
  assert_true(schema is JsonSchema::OneOf(_))
  guard Enumerable::parse_enumerable(schema) is Some(enum_values) else {
    raise fail("Failed to parse enumerable")
  }
  inspect(
    enum_values,
    content=(
      #|[{tag: "Single", positionals: None, params: None}, {tag: "A", positionals: Some([Integer(minimum=None, maximum=None, exclusiveMinimum=None, exclusiveMaximum=None, multipleOf=None, description=None), String(minLength=None, maxLength=None, pattern=None, format=None, enum_=None, contentEncoding=None, contentMediaType=None, description=None)]), params: None}, {tag: "B", positionals: Some([Number(minimum=None, maximum=None, exclusiveMinimum=None, exclusiveMaximum=None, multipleOf=None, description=None)]), params: None}, {tag: "C", positionals: Some([Integer(minimum=None, maximum=None, exclusiveMinimum=None, exclusiveMaximum=None, multipleOf=None, description=None)]), params: None}]

    ),
  )
  // let value : Json = {
  // 
  // }

  // println("Parsed enum values: \{enum_values}")
  // assert enum_values.length() == 4
  // assert enum_values[0] == Enumerable::new(
  //   "A",
  //   [JsonSchema::Integer, JsonSchema::String],
  //   None,
  // )
  // assert enum_values[1] == Enumerable::new(
  //   "B",
  //   [JsonSchema::Number],
  //   None,
  // )
  // assert enum_values[2] == Enumerable::new("C", [], None)
  // assert enum_values[3] == Enumerable::new(
  //   "D",
  //   [JsonSchema::Integer, JsonSchema::String],
  //   Some(JsonSchema::Object(properties=Some({"extra": JsonSchema::Boolean}), ..)),
  // )
}
