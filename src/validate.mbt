///|
/// Example:
/// ```
/// let jsonschema : Json = { "type": "string" }
/// let validator = build_validator(jsonschema)
/// let _result = validator.validate("hello")
/// ```
pub fn build_validator(raw : Json) -> Validator raise {
  let schema : JsonSchema = @json.from_json(raw) catch {
    err => raise ParseError::JsonDecodeError(err)
  }
  let resolver = Resolver::new(raw)
  Validator::{ schema, resolver }
}

///|
struct Validator {
  schema : JsonSchema
  resolver : Resolver
}

///|
pub fn Validator::with_resolver(
  schema : JsonSchema,
  resolver : Resolver,
) -> Validator {
  Validator::{ schema, resolver }
}

///|
pub fn Validator::validate(
  self : Validator,
  input : Json,
) -> Result[Unit, Array[ValidationError]] {
  let errors = self.schema.validate_internal(input, resolver=self.resolver)
  if errors.length() == 0 {
    Ok(())
  } else {
    Err(errors)
  }
}

///|
/// internal validator for schema
pub fn JsonSchema::validate(
  self : JsonSchema,
  value : Json,
) -> Result[Unit, Array[ValidationError]] raise Error {
  let resolver = Resolver::new({}) // dummy resolver
  match self.validate_internal(value, resolver~) {
    [] => Ok(())
    errors => Err(errors)
  }
}

///|
fn JsonSchema::validate_internal(
  self : JsonSchema,
  value : Json,
  resolver~ : Resolver,
  json_path? : JsonPointer = JsonPointer::Root,
  schema_path? : JsonPointer = JsonPointer::Root,
) -> Array[ValidationError] {
  match self {
    Const(s) =>
      if value != s.value {
        [
          ValidationError::new(
            value,
            json_path,
            schema_path,
            "Value does not match constant value \{s.value}",
          ),
        ]
      } else {
        []
      }
    Integer(c) => {
      // TODO: Move to NumberConstraint
      // check intger type
      if value is @json.Number(v, ..) {
        let iv = v.to_int()
        if iv.to_double() != v {
          return [
            ValidationError::new(
              value, json_path, schema_path, "Value is not a number",
            ),
          ]
        }
      }
      c.validate(value, resolver, json_path~, schema_path~)
    }
    Enum({ values }) =>
      if !values.contains(value) {
        [
          ValidationError::new(
            value,
            json_path,
            schema_path,
            "\{value} is not in \{values}",
          ),
        ]
      } else {
        []
      }
    Boolean(s) => s.validate(value, resolver, json_path~, schema_path~)
    Ref(s) => s.validate(value, resolver, json_path~, schema_path~)
    Null(s) => s.validate(value, resolver, json_path~, schema_path~)
    Any(s) => s.validate(value, resolver, json_path~, schema_path~)
    Number(c) => c.validate(value, resolver, json_path~, schema_path~)
    String(c) => c.validate(value, resolver, json_path~, schema_path~)
    Array(c) => c.validate(value, resolver, json_path~, schema_path~)
    Object(v) => v.validate(value, resolver, json_path~, schema_path~)
    AllOf(s) => s.validate(value, resolver, json_path~, schema_path~)
    OneOf(s) => s.validate(value, resolver, json_path~, schema_path~)
    AnyOf(s) => s.validate(value, resolver, json_path~, schema_path~)
    // WIP
    Not(_schema) =>
      // TODO: implement Not validation
      []
  }
}
