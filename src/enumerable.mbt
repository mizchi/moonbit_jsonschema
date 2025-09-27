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
  for schema in schemas.schemas {
    match schema {
      // {"const": "A"}
      Const(String(tag_value)) =>
        parsed.push(Enumerable::new(tag_value, None, None))
      // [{"const": "A"}, { "type": "array", .. }]
      Array({ prefix_items: Some([JsonSchema::Const(String(tag_value))]), .. }) =>
        parsed.push(Enumerable::new(tag_value, None, None))
      // [{"const": "A"}, ..]
      Array(
        { prefix_items: Some([Const(String(tag_value)), .. child_schemas]), .. }
      ) => {
        let matched = match child_schemas.to_array() {
          [] => { tag: tag_value, positionals: None, params: None }
          // [.. positionals, Object(properties=Some(params), ..)] =>
          [.. positionals, Object(v)] =>
            {
              tag: tag_value,
              positionals: positionals.to_array() |> Some,
              params: v.properties,
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
      #|[{tag: "Single", positionals: None, params: None}, {tag: "A", positionals: Some([Integer({minimum: None, maximum: None, exclusive_minimum: None, exclusive_maximum: None}), String({min_length: None, max_length: None, enum_: None})]), params: None}, {tag: "B", positionals: Some([Number({minimum: None, maximum: None, exclusive_minimum: None, exclusive_maximum: None})]), params: None}, {tag: "C", positionals: Some([Integer({minimum: None, maximum: None, exclusive_minimum: None, exclusive_maximum: None})]), params: None}]
    ),
  )
}

///|
test "validate enum" {
  let b = Builder::new()
  let reschema = b.one_of([
    b.array(prefix_items=[b.const_("A"), b.integer(), b.string()]),
    b.array(prefix_items=[b.const_("B"), b.number()]),
    b.array(prefix_items=[b.const_("C"), b.integer()]),
    b.const_("D"),
    b.array(prefix_items=[
      b.const_("Paramed"),
      b.object(properties={ "a": b.integer() }, required=["a"]),
    ]),
  ])
  reschema.validate("Not match") |> assert_err
  reschema.validate(["A", 1, "str"]) |> assert_ok
  reschema.validate(["B", 3.14]) |> assert_ok
  reschema.validate(["B", "err"]) |> assert_err
  reschema.validate(["C", 42]) |> assert_ok
  reschema.validate("D") |> assert_ok
  reschema.validate("NotExist") |> assert_err
  reschema.validate(["Paramed", { "a": 10 }]) |> assert_ok
  reschema.validate(["Paramed", { "a": "not a number" }]) |> assert_err
}
