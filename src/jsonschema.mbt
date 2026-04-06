// JSON Schema types and definitions

///|
pub trait Validatable {
  validate(
    Self,
    Json,
    resolver~ : Resolver,
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
  Number(NumberSchema)
  Integer(IntegerSchema)
  Array(ArraySchema)
  Object(ObjectSchema)
  AnyOf(AnyOfSchema)
  AllOf(AllOfSchema)
  OneOf(OneOfSchema)
  Ref(RefSchema)
  Enum(EnumSchema)
  Const(ConstSchema)
  // Not(JsonSchema)
  // If(Schema, Schema?, Schema?) // if, then, else
} derive(Show, Eq)

///|
pub impl Validatable for JsonSchema with validate(
  self,
  value,
  resolver~,
  json_path~,
  schema_path~,
) {
  match self {
    Const(s) => s.validate(value, resolver~, json_path~, schema_path~)
    Integer(s) => s.validate(value, resolver~, json_path~, schema_path~)
    Enum(s) => s.validate(value, resolver~, json_path~, schema_path~)
    Boolean(s) => s.validate(value, resolver~, json_path~, schema_path~)
    Ref(s) => s.validate(value, resolver~, json_path~, schema_path~)
    Null(s) => s.validate(value, resolver~, json_path~, schema_path~)
    Any(s) => s.validate(value, resolver~, json_path~, schema_path~)
    Number(c) => c.validate(value, resolver~, json_path~, schema_path~)
    String(c) => c.validate(value, resolver~, json_path~, schema_path~)
    Array(c) => c.validate(value, resolver~, json_path~, schema_path~)
    Object(v) => v.validate(value, resolver~, json_path~, schema_path~)
    AllOf(s) => s.validate(value, resolver~, json_path~, schema_path~)
    OneOf(s) => s.validate(value, resolver~, json_path~, schema_path~)
    AnyOf(s) => s.validate(value, resolver~, json_path~, schema_path~)
    // WIP
    // Not(_schema) =>
    //   // TODO: implement Not validation
    //   []
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
  match obj {
    { "type": "any", .. } =>
      AnySchema::from_json(json, json_path) |> JsonSchema::Any
    { "const": value, .. } => Const({ value, })
    { "$ref": String(refstr), .. } => {
      let pointer = JsonPointer::from_string(refstr).unwrap()
      JsonSchema::Ref(RefSchema::{ pointer, })
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
      NumberSchema::from_json(json, json_path) |> JsonSchema::Number
    { "type": "integer", .. } =>
      IntegerSchema::from_json(json, json_path) |> JsonSchema::Integer
    { "anyOf": Array(schemas), .. } =>
      JsonSchema::AnyOf({
        schemas: schemas.map(s => {
          @json.from_json(s, path=json_path.add_key("anyOf"))
        }),
      })
    { "allOf": Array(schemas), .. } =>
      JsonSchema::AllOf({
        schemas: schemas.map(s => {
          @json.from_json(s, path=json_path.add_key("allOf"))
        }),
      })
    { "oneOf": Array(schemas), .. } =>
      JsonSchema::OneOf({
        schemas: schemas.mapi((i, s) => {
          @json.from_json(s, path=json_path.add_key("oneOf").add_index(i))
        }),
        parsed_enumerable: None,
        parsed_nullable: None,
      })
    //   JsonSchema::Not(@json.from_json(schema, path=json_path.add_key("not")))
    { "enum": Array(values), .. } => JsonSchema::Enum(EnumSchema::{ values, })
    _ => JsonSchema::Any(AnySchema::{  })
  }
}

///| Primitive types

///|
pub struct AnySchema {} derive(Show, Eq, FromJson, ToJson)

///|
impl Validatable for AnySchema with validate(
  _self,
  _value,
  resolver~,
  json_path~,
  schema_path~,
) {
  ignore((json_path, schema_path, resolver))
  []
}

///|
pub struct NullSchema {} derive(Show, Eq, FromJson, ToJson)

///|
impl Validatable for NullSchema with validate(
  _self,
  value,
  resolver~,
  json_path~,
  schema_path~,
) {
  ignore((json_path, schema_path, resolver))
  match value {
    Null => []
    _ =>
      [ValidationError::new(value, json_path, schema_path, "Value is not null")]
  }
  // []
}

///|
pub struct BooleanSchema {} derive(Show, Eq, FromJson, ToJson)

///|
impl Validatable for BooleanSchema with validate(
  _self,
  value,
  resolver~,
  json_path~,
  schema_path~,
) {
  ignore((json_path, schema_path, resolver))
  match value {
    True => []
    False => []
    _ =>
      [
        ValidationError::new(
          value, json_path, schema_path, "Value is not a boolean",
        ),
      ]
  }
}
