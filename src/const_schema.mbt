///|
pub struct ConstSchema {
  value : Json
} derive(Show, Eq, FromJson)

///|
impl Validatable for ConstSchema with to_json_schema(self) {
  { "const": self.value.to_json() }
}

///|
impl Validatable for ConstSchema with parse(json) {
  ...
}

///|
impl Validatable for ConstSchema with validate(
  _self,
  value,
  _resolver,
  json_path~,
  schema_path~,
) {
  ...
}

///|
pub struct EnumSchema {
  values : Array[Json]
} derive(Show, Eq, FromJson, ToJson)

///|
impl Validatable for EnumSchema with to_json_schema(self) {
  { "enum": self.values.to_json() }
}

///|
impl Validatable for EnumSchema with parse(json) {
  ...
}

///|
impl Validatable for EnumSchema with validate(
  _self,
  value,
  _resolver,
  json_path~,
  schema_path~,
) {
  ...
}
