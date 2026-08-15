///|
pub struct ConstSchema {
  value : Json
} derive(Debug, Eq, FromJson, ToJson)

///|
impl JsonSchemaSerializable for ConstSchema with fn to_json_schema(self) {
  { "const": @json.to_json(self.value) }
}

///|
impl JsonSchemaSerializable for ConstSchema with fn parse(_json) {
  ...
}

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
impl JsonSchemaSerializable for EnumSchema with fn to_json_schema(self) {
  { "enum": self.values.to_json() }
}

///|
impl JsonSchemaSerializable for EnumSchema with fn parse(_json) {
  ...
}

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
