///|
pub struct ConstSchema {
  value : Json
} derive(Show, Eq, FromJson, ToJson)

///|
impl Validatable for ConstSchema with validate(
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
        "Value does not match constant value \{self.value}",
      ),
    ]
  } else {
    []
  }
}

///|
pub struct EnumSchema {
  values : Array[Json]
} derive(Show, Eq, FromJson, ToJson)

///|
impl Validatable for EnumSchema with validate(
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
        "\{value} is not in \{self.values}",
      ),
    ]
  } else {
    []
  }
}
