// builder

///|
/// { "type": "string" }
pub fn JsonSchema::string(
  minLength? : Int,
  maxLength? : Int,
  pattern? : String,
  format? : String,
  enum_? : Array[String],
  contentEncoding? : String,
  contentMediaType? : String,
  description? : String,
) -> JsonSchema {
  JsonSchema::String(
    description~,
    minLength~,
    maxLength~,
    pattern~,
    format~,
    enum_~,
    contentEncoding~,
    contentMediaType~,
  )
}

///|
/// { "type": "number" }
pub fn JsonSchema::number(
  description? : String,
  minimum? : Double,
  maximum? : Double,
  exclusiveMinimum? : Double,
  exclusiveMaximum? : Double,
  multipleOf? : Double,
) -> JsonSchema {
  JsonSchema::Number(
    description~,
    minimum~,
    maximum~,
    exclusiveMinimum~,
    exclusiveMaximum~,
    multipleOf~,
  )
}

///|
/// { "type": "integer" }
pub fn JsonSchema::integer(
  description? : String,
  minimum? : Int,
  maximum? : Int,
  exclusiveMinimum? : Int,
  exclusiveMaximum? : Int,
  multipleOf? : Int,
) -> JsonSchema {
  JsonSchema::Integer(
    description~,
    minimum~,
    maximum~,
    exclusiveMinimum~,
    exclusiveMaximum~,
    multipleOf~,
  )
}

///|
/// { "type": "array" }
pub fn JsonSchema::array(
  items? : JsonSchema,
  prefixItems? : Array[JsonSchema],
  contains? : JsonSchema,
  minContains? : Int,
  maxContains? : Int,
  minItems? : Int,
  maxItems? : Int,
  uniqueItems? : Bool,
  description? : String,
) -> JsonSchema {
  JsonSchema::Array(
    description~,
    items~,
    prefixItems~,
    contains~,
    minContains~,
    maxContains~,
    minItems~,
    maxItems~,
    uniqueItems~,
  )
}

///|
/// { "type": "null" }
pub fn JsonSchema::null(description? : String) -> JsonSchema {
  JsonSchema::Null(description~)
}

///|
/// { "type": "boolean" }
pub fn JsonSchema::boolean(description? : String) -> JsonSchema {
  JsonSchema::Boolean(description~)
}

///|
/// { "type": "any" }
pub fn JsonSchema::any(description? : String) -> JsonSchema {
  JsonSchema::Any(description~)
}

///|
/// { "type": "object" }
pub fn JsonSchema::object(
  description? : String,
  properties? : Map[String, JsonSchema],
  required? : Array[String],
  additionalProperties? : JsonSchema,
  patternProperties? : Map[String, JsonSchema],
  propertyNames? : JsonSchema,
  dependentSchemas? : Map[String, JsonSchema],
  dependentRequired? : Map[String, Array[String]],
  minProperties? : Int,
  maxProperties? : Int,
) -> JsonSchema {
  JsonSchema::Object(
    description~,
    properties~,
    required~,
    additionalProperties~,
    patternProperties~,
    propertyNames~,
    dependentSchemas~,
    dependentRequired~,
    minProperties~,
    maxProperties~,
  )
}

///|
/// { "enum": [...] }
pub fn JsonSchema::enum_(values : Array[Json]) -> JsonSchema {
  JsonSchema::Enum(values)
}

///|
/// { "const": value }
pub fn JsonSchema::const_(value : Json) -> JsonSchema {
  JsonSchema::Const(value)
}

///|
/// { "oneOf": [...] }
pub fn JsonSchema::oneOf(schemas : Array[JsonSchema]) -> JsonSchema {
  JsonSchema::OneOf(schemas)
}

///|
/// { "oneOf": [...] }
pub fn JsonSchema::enumerableOneOf(
  tag : String,
  schemas : Array[JsonSchema],
  params~ : JsonSchema?,
) -> JsonSchema {
  // TODO: validate schemas
  if params is Some(params) {
    JsonSchema::OneOf([
      JsonSchema::const_(tag.to_json()),
      JsonSchema::array(prefixItems=schemas),
      params,
    ])
  } else {
    JsonSchema::OneOf([
      JsonSchema::const_(tag.to_json()),
      JsonSchema::array(prefixItems=schemas),
    ])
  }
}

///|
/// { "anyOf": [...] }
pub fn JsonSchema::anyOf(schemas : Array[JsonSchema]) -> JsonSchema {
  JsonSchema::AnyOf(schemas)
}

///|
/// { "allOf": [...] }
pub fn JsonSchema::allOf(schemas : Array[JsonSchema]) -> JsonSchema {
  JsonSchema::AllOf(schemas)
}

///|
/// { "$ref": ... }
pub fn JsonSchema::ref_(pointer : String) -> JsonSchema {
  JsonSchema::Ref(pointer)
}

///|
test "parse object" {
  let input =
    #|{
    #|  "type": "object",
    #|  "properties": {
    #|    "name": { "type": "string" },
    #|    "age": { "type": "number" }
    #|  },
    #|  "required": ["name", "age"]
    #|}
  let jsonschema : Json = @json.parse(input)
  let schema : JsonSchema = @json.from_json(jsonschema)
  schema.validate({ "name": "Alice", "age": 30.0 }).unwrap()
  |> inspect(content="()")
  schema.validate({ "name": 42, "age": 30.0 }).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Number(42), json_path: #/name, schema_path: #/properties/name, message: "Value is not a string", children: None}]
    ),
  )
  schema.to_json().to_string()
  |> inspect(
    content=(
      #|Object({"type": String("object"), "properties": Object({"name": Object({"type": String("string")}), "age": Object({"type": String("number")})}), "required": Array([String("name"), String("age")])})
    ),
  )
  ()
}

///|
test "parse array" {
  let input =
    #|{
    #|  "type": "array",
    #|  "items": { "type": "string" }
    #|}
  let jsonschema : Json = @json.parse(input)
  let schema : JsonSchema = @json.from_json(jsonschema)
  schema.validate(["a", "b"]).unwrap() |> inspect(content="()")
  schema.validate(["a", 1])
  |> inspect(
    content=(
      #|Err([{input: Number(1), json_path: #/1, schema_path: #/items, message: "Value is not a string", children: None}])
    ),
  )
}

///|
test "parse nested" {
  let input =
    #|{
    #|  "type": "object",
    #|  "properties": {
    #|    "name": { "type": "string" },
    #|    "age": { "type": "integer" },
    #|    "friends": { "type": "array", "items": { "type": "string" } },
    #|    "nullValue": { "type": "null" },
    #|    "anyValue": { "type": "any" }
    #|  },
    #|  "required": ["name", "age", "friends", "nullValue", "anyValue"]
    #|}
  let jsonschema : Json = @json.parse(input)
  let schema : JsonSchema = @json.from_json(jsonschema)
  schema
  .validate({
    "name": "Alice",
    "age": 30,
    "friends": ["Bob"],
    "nullValue": null,
    "anyValue": "anything",
  })
  .unwrap()
  |> inspect(content="()")
  schema.validate({
    "name": "Alice",
    "age": 30,
    "friends": [1],
    "nullValue": null,
    "anyValue": "anything",
  })
  |> inspect(
    content=(
      #|Err([{input: Number(1), json_path: #/friends/0, schema_path: #/properties/friends/items, message: "Value is not a string", children: None}])
    ),
  )
}

///|
test "convert type: [string, null] to anyOf" {
  let input =
    #|{
    #|  "type": ["string", "null"]
    #|}
  let jsonschema : Json = @json.parse(input)
  let schema : JsonSchema = @json.from_json(jsonschema)
  assert_eq(
    schema,
    JsonSchema::anyOf([JsonSchema::string(), JsonSchema::null()]),
  )
}
