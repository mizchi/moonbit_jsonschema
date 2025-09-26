///|
pub struct StringConstraint {
  min_length : Int?
  max_length : Int?
  enum_ : Array[String]?
} derive (
  Show,
  Eq,
  FromJson(
    fields(
      min_length(rename="minLength"),
      max_length(rename="maxLength"),
      enum_(rename="enum"),
    ),
  ),
  ToJson(
    fields(
      min_length(rename="minLength"),
      max_length(rename="maxLength"),
      enum_(rename="enum"),
    ),
  ),
)

///|
impl Validatable for StringConstraint with to_json_schema(self) {
  with_type_property(self.to_json(), "string")
}

///|
impl Validatable for StringConstraint with from_json_schema(json, json_path) {
  try
    StringConstraint::from_json(json, json_path) |> JsonSchema::String |> Ok
  catch {
    _ => Err("Failed to parse StringConstraint".to_string())
  }
  // parsed |> Ok
}

///|
impl Validatable for StringConstraint with validate(
  self,
  input,
  json_path~,
  schema_path~,
) {
  guard input is Json::String(input) else {
    return [
      ValidationError::new(
        input, json_path, schema_path, "Value is not a string",
      ),
    ]
  }
  let errors : Array[ValidationError] = []
  let len = input.length()
  if self.min_length is Some(min) && len < min {
    errors.push(
      ValidationError::new(
        input.to_json(),
        json_path,
        schema_path.key("minLength"),
        "String length \{len} is less than minimum \{min}",
      ),
    )
  }
  if self.max_length is Some(max) && len > max {
    return [
      ValidationError::new(
        input.to_json(),
        json_path,
        schema_path.key("maxLength"),
        "String length \{len} is greater than maximum \{max}",
      ),
    ]
  }
  if self.enum_ is Some(enum_values) && !enum_values.contains(input) {
    return [
      ValidationError::new(
        input.to_json(),
        json_path,
        schema_path.key("enum"),
        "\{input} is not in \{enum_values}",
      ),
    ]
  }
  errors
}
