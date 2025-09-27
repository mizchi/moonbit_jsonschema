// JSON Schema types and definitions

///|
trait Validatable {
  from_json_schema(Json) -> Result[JsonSchema, String]
  to_json_schema(Self) -> Json
  validate(
    Self,
    Json,
    Resolver,
    json_path~ : JsonPointer,
    schema_path~ : JsonPointer,
  ) -> Array[ValidationError]
}

///|
pub struct AnySchema {} derive(Show, Eq, FromJson, ToJson)

///|
impl Validatable for AnySchema with to_json_schema(self) {
  with_type_property({}, "any")
  // { "type": "any" }
}

///|
impl Validatable for AnySchema with from_json_schema(json) {
  try {
    let v : AnySchema = @json.from_json(json)
    v |> JsonSchema::Any |> Ok
  } catch {
    _ => Err("Failed to parse AnySchema".to_string())
  }
}

///|
impl Validatable for AnySchema with validate(
  _self,
  _value,
  _resolver,
  json_path~,
  schema_path~,
) {
  ignore((json_path, schema_path))
  []
}

///|any

///|
/// JsonSchema
pub enum JsonSchema {
  Any(AnySchema)
  Null(description~ : String?)
  Boolean(description~ : String?)
  String(StringSchema)
  Number(NumberConstraint)
  Integer(NumberConstraint)
  Array(ArraySchema)
  Object(ObjectSchema)
  Enum(Array[Json])
  Const(Json)
  AnyOf(Array[JsonSchema])
  AllOf(Array[JsonSchema])
  OneOf(Array[JsonSchema])
  Not(JsonSchema)
  Ref(JsonPointer)
  // If(Schema, Schema?, Schema?) // if, then, else
} derive(Show, Eq)

///|
/// TODO: Remove this helper function if possible
fn with_type_property(json : Json, type_name : String) -> Json {
  guard json is Json::Object(obj) else { return json }
  let json : Map[String, Json] = { "type": type_name.to_json() }
  for k, v in obj {
    json[k] = v
  }
  return json.to_json()
}

///|
pub impl ToJson for JsonSchema with to_json(self) -> Json {
  match self {
    Any(c) => c.to_json_schema()
    Null(_) => { "type": "null" }
    Boolean(_) => { "type": "boolean" }
    String(c) => c.to_json_schema()
    Number(c) => c.to_json_schema()
    Integer(c) => c.to_json_schema()
    Array(constraints) => constraints.to_json_schema()
    Object(c) => with_type_property(c.to_json(), "object")
    Ref(pointer) => { "$ref": pointer.to_string() }
    Const(value) => { "const": value }
    Enum(values) => { "enum": values.to_json() }
    JsonSchema::AnyOf(schemas) =>
      { "anyOf": schemas.map(fn(s) { s.to_json() }) }
    JsonSchema::AllOf(schemas) =>
      { "allOf": schemas.map(fn(s) { s.to_json() }) }
    JsonSchema::OneOf(schemas) =>
      { "oneOf": schemas.map(fn(s) { s.to_json() }) }
    JsonSchema::Not(schema) => { "not": schema }
  }
}

///|
pub impl @json.FromJson for JsonSchema with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> JsonSchema raise {
  guard json is Json::Object(obj) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let description = match obj.get("description") {
    Some(String(desc)) => Some(desc)
    _ => None
  }
  let b = Builder::new()
  match obj {
    { "const": value, .. } => Const(value)
    { "$ref": String(ref_expr), .. } =>
      // TODO: validate ref_expr
      JsonPointer::from_string(ref_expr).unwrap() |> Ref
    { "type": Array(["null", String(item_type)]), .. } => {
      let schema = match item_type {
        "string" => b.string()
        "number" => b.number()
        "integer" => b.integer()
        "boolean" => b.boolean()
        // TODO: raise error if unsupported type
        _ => b.any()
      }
      b.anyOf([schema, JsonSchema::Null(description=None)])
    }
    { "type": @json.Array([String(item_type), "null"]), .. } => {
      let schema = match item_type {
        "string" => b.string()
        "number" => b.number()
        "integer" => b.integer()
        "boolean" => b.boolean()
        // TODO: raise error if unsupported type
        _ => b.any()
      }
      b.anyOf([schema, b.null()])
    }
    { "type": "object", .. } =>
      ObjectSchema::from_json(json, json_path) |> JsonSchema::Object
    { "type": "array", .. } =>
      ArraySchema::from_json(json, json_path) |> JsonSchema::Array
    { "type": "null", .. } => JsonSchema::Null(description~)
    { "type": "boolean", .. } => JsonSchema::Boolean(description~)
    { "type": "string", .. } =>
      StringSchema::from_json(json, json_path) |> JsonSchema::String
    { "type": "number", .. } =>
      NumberConstraint::from_json(json, json_path) |> JsonSchema::Number
    { "type": "integer", .. } =>
      NumberConstraint::from_json(json, json_path) |> JsonSchema::Integer
    { "anyOf": Array(schemas), .. } =>
      JsonSchema::AnyOf(
        schemas.map(fn(s) {
          @json.from_json(s, path=json_path.add_key("anyOf"))
        }),
      )
    { "allOf": Array(schemas), .. } =>
      JsonSchema::AllOf(
        schemas.map(fn(s) {
          @json.from_json(s, path=json_path.add_key("allOf"))
        }),
      )
    { "oneOf": Array(schemas), .. } =>
      JsonSchema::OneOf(
        schemas.mapi(fn(i, s) {
          @json.from_json(s, path=json_path.add_key("oneOf").add_index(i))
        }),
      )
    { "not": schema, .. } =>
      JsonSchema::Not(@json.from_json(schema, path=json_path.add_key("not")))
    { "enum": Array(values), .. } => JsonSchema::Enum(values)
    _ => JsonSchema::Any(AnySchema::{  })
  }
}
