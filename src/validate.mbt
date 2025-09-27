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
  // let errors = self.schema.validate(input, self.resolver)
  if errors.length() == 0 {
    Ok(())
  } else {
    Err(errors)
  }
}
