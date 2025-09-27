// JSON Schema types and definitions

///|
priv trait Validatable {
  parse(Json) -> Result[JsonSchema, String]
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
/// JsonSchema
pub enum JsonSchema {
  Any(AnySchema)
  Null(NullSchema)
  Boolean(BooleanSchema)
  String(StringSchema)
  Number(NumberConstraint)
  Integer(NumberConstraint)
  Array(ArraySchema)
  Object(ObjectSchema)
  AnyOf(AnyOfSchema)
  AllOf(AllOfSchema)
  OneOf(OneOfSchema)
  //wip
  Enum(Array[Json])
  Const(Json)
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
    Any(s) => s.to_json_schema()
    Null(s) => s.to_json_schema()
    Boolean(s) => s.to_json_schema()
    String(s) => s.to_json_schema()
    Number(s) => s.to_json_schema()
    Integer(s) => s.to_json_schema()
    Array(s) => s.to_json_schema()
    Object(s) => s.to_json_schema()
    JsonSchema::AnyOf(s) => s.to_json_schema()
    JsonSchema::AllOf(s) => s.to_json_schema()
    JsonSchema::OneOf(s) => s.to_json_schema()
    // wip
    Ref(pointer) => { "$ref": pointer.to_string() }
    Const(value) => { "const": value }
    Enum(values) => { "enum": values.to_json() }
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
  let b = Builder::new()
  match obj {
    { "type": "any", .. } =>
      AnySchema::from_json(json, json_path) |> JsonSchema::Any
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
      b.anyOf([schema, JsonSchema::Null(NullSchema::{  })])
    }
    // like a ["null", "string"]
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
    { "type": "null", .. } => JsonSchema::Null(NullSchema::{  })
    { "type": "boolean", .. } => JsonSchema::Boolean(BooleanSchema::{  })
    { "type": "string", .. } =>
      StringSchema::from_json(json, json_path) |> JsonSchema::String
    { "type": "number", .. } =>
      NumberConstraint::from_json(json, json_path) |> JsonSchema::Number
    { "type": "integer", .. } =>
      NumberConstraint::from_json(json, json_path) |> JsonSchema::Integer
    { "anyOf": Array(schemas), .. } =>
      JsonSchema::AnyOf({
        schemas: schemas.map(fn(s) {
          @json.from_json(s, path=json_path.add_key("anyOf"))
        }),
      })
    { "allOf": Array(schemas), .. } =>
      JsonSchema::AllOf({
        schemas: schemas.map(fn(s) {
          @json.from_json(s, path=json_path.add_key("allOf"))
        }),
      })
    { "oneOf": Array(schemas), .. } =>
      JsonSchema::OneOf({
        schemas: schemas.mapi(fn(i, s) {
          @json.from_json(s, path=json_path.add_key("oneOf").add_index(i))
        }),
      })
    { "not": schema, .. } =>
      JsonSchema::Not(@json.from_json(schema, path=json_path.add_key("not")))
    { "enum": Array(values), .. } => JsonSchema::Enum(values)
    _ => JsonSchema::Any(AnySchema::{  })
  }
}

///| Primitive types

///|
pub struct AnySchema {} derive(Show, Eq, FromJson, ToJson)

///|
impl Validatable for AnySchema with to_json_schema(_self) {
  with_type_property({}, "any")
}

///|
impl Validatable for AnySchema with parse(json) {
  if not(json is { "type": "any", .. }) {
    return Err("Expected an object for AnySchema".to_string())
  }
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

///|
pub struct NullSchema {} derive(Show, Eq, FromJson, ToJson)

///|
impl Validatable for NullSchema with to_json_schema(_self) {
  with_type_property({}, "null")
}

///|
impl Validatable for NullSchema with parse(json) {
  if not(json is { "type": "null", .. }) {
    return Err("Expected an object for NullSchema".to_string())
  }
  try {
    let v : NullSchema = @json.from_json(json)
    v |> JsonSchema::Null |> Ok
  } catch {
    _ => Err("Failed to parse NullSchema".to_string())
  }
}

///|
impl Validatable for NullSchema with validate(
  _self,
  value,
  _resolver,
  json_path~,
  schema_path~,
) {
  ignore((json_path, schema_path))
  match value {
    @json.Null => []
    _ =>
      [ValidationError::new(value, json_path, schema_path, "Value is not null")]
  }
  // []
}

///|
pub struct BooleanSchema {} derive(Show, Eq, FromJson, ToJson)

///|
impl Validatable for BooleanSchema with to_json_schema(_self) {
  with_type_property({}, "boolean")
}

///|
impl Validatable for BooleanSchema with parse(json) {
  if not(json is { "type": "boolean", .. }) {
    return Err("Expected an object for NullSchema".to_string())
  }
  try {
    let v : BooleanSchema = @json.from_json(json)
    v |> JsonSchema::Boolean |> Ok
  } catch {
    _ => Err("Failed to parse NullSchema".to_string())
  }
}

///|
impl Validatable for BooleanSchema with validate(
  _self,
  value,
  _resolver,
  json_path~,
  schema_path~,
) {
  ignore((json_path, schema_path))
  match value {
    @json.True => []
    @json.False => []
    _ =>
      [
        ValidationError::new(
          value, json_path, schema_path, "Value is not a boolean",
        ),
      ]
  }
}
