///|
/// OneOf schema
pub struct OneOfSchema {
  schemas : Array[JsonSchema]
} derive(Show, Eq)

///|
impl JsonSchemaSerializable for OneOfSchema with to_json_schema(self) {
  { "oneOf": self.schemas.map(fn(s) { s.to_json() }) }
}

///|
impl JsonSchemaSerializable for OneOfSchema with parse(json) {
  ...
}

///|
impl Validatable for OneOfSchema with validate(
  self,
  value,
  resolver,
  json_path~,
  schema_path~,
) {
  let errors : Array[ValidationError] = []
  let mut passed = 0
  for idx, schema in self.schemas {
    let sub_errors = schema.validate_internal(
      value,
      json_path~,
      schema_path=schema_path.key("oneOf").index(idx),
      resolver~,
    )
    if sub_errors.length() == 0 {
      passed += 1
    } else {
      errors.append(sub_errors)
    }
  }
  if passed == 1 {
    []
  } else {
    errors.push(
      ValidationError::new(
        value,
        json_path,
        schema_path.key("oneOf"),
        "Value does not match exactly one schema in oneOf",
      ),
    )
    errors
  }
}
