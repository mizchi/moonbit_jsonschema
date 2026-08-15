///|
pub struct AnyOfSchema {
  schemas : Array[JsonSchema]
} derive(Debug, Eq)

///|
impl JsonSchemaSerializable for AnyOfSchema with fn to_json_schema(self) {
  { "anyOf": self.schemas.map(fn(s) { s.to_json() }) }
}

///|
impl JsonSchemaSerializable for AnyOfSchema with fn parse(_json) {
  ...
}

///|
impl Validatable for AnyOfSchema with fn validate(
  self,
  value,
  resolver~,
  json_path~,
  schema_path~,
) {
  let errors : Array[ValidationError] = []
  let mut passed = 0
  for idx, schema in self.schemas {
    let sub_errors = schema.validate(
      value,
      json_path~,
      schema_path=schema_path.key("anyOf").index(idx),
      resolver~,
    )
    if sub_errors.length() == 0 {
      passed += 1
    } else {
      errors.append(sub_errors)
    }
  }
  if passed > 0 {
    []
  } else {
    errors.push(
      ValidationError::new(
        value,
        json_path,
        schema_path.key("anyOf"),
        "Value does not match any schema in anyOf",
      ),
    )
    errors
  }
}
