///|
pub struct ConstSchema {
  value : Json
} derive(Debug, Eq, FromJson, ToJson)

///|
impl Validatable for ConstSchema with fn validate(
  self,
  value,
  resolver~,
  json_path~,
  schema_path~,
) {
  ignore(resolver)
  // ...
  if value != self.value {
    [
      ValidationError::new(
        value,
        json_path,
        schema_path,
        "Value does not match constant value \{@debug.to_string(self.value)}",
      ),
    ]
  } else {
    []
  }
}

///|
pub struct EnumSchema {
  values : Array[Json]
} derive(Debug, Eq, FromJson, ToJson)

///|
impl Validatable for EnumSchema with fn validate(
  self,
  value,
  resolver~,
  json_path~,
  schema_path~,
) {
  ignore(resolver)
  if !self.values.contains(value) {
    [
      ValidationError::new(
        value,
        json_path,
        schema_path,
        "\{@debug.to_string(value)} is not in \{@debug.to_string(self.values)}",
      ),
    ]
  } else {
    []
  }
}
