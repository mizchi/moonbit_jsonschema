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
    Boolean(_) =>
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
    Null(_) =>
      match value {
        @json.Null => []
        _ =>
          [
            ValidationError::new(
              value, json_path, schema_path, "Value is not null",
            ),
          ]
      }
    Any(_) => []
    Const(expected) =>
      if value != expected {
        [
          ValidationError::new(
            value,
            json_path,
            schema_path,
            "Value does not match constant value \{expected}",
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
    Number(c) => c.validate(value, resolver, json_path~, schema_path~)
    String(c) => c.validate(value, resolver, json_path~, schema_path~)
    Array(c) => c.validate(value, resolver, json_path~, schema_path~)
    Object(v) => v.validate(value, resolver, json_path~, schema_path~)
    Enum(enum_values) =>
      if !enum_values.contains(value) {
        [
          ValidationError::new(
            value,
            json_path,
            schema_path,
            "\{value} is not in \{enum_values}",
          ),
        ]
      } else {
        []
      }
    Ref(pointer) =>
      match resolver.resolve(pointer) {
        Some(resolved_schema) => {
          // let opath = ObjectPath::from_json_pointer(ref_expr)
          let errors = resolved_schema.validate_internal(
            value,
            json_path~,
            // TODO: fix schema_path to reference path
            schema_path=schema_path.key("$ref"),
            resolver~,
          )
          errors
        }
        None =>
          [
            ValidationError::new(
              value,
              json_path,
              schema_path.key("$ref"),
              "Failed to resolve reference '\{pointer}'",
            ),
          ]
      }
    Not(_schema) =>
      // TODO: implement Not validation
      []
    //   raise RuntimeError::Unsupported("not schema validation not implemented")
    AllOf(s) => s.validate(value, resolver, json_path~, schema_path~)
    OneOf(s) => s.validate(value, resolver, json_path~, schema_path~)
    AnyOf(s) => s.validate(value, resolver, json_path~, schema_path~)
  }
}
