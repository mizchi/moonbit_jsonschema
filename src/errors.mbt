///|
/// JsonSchema compilation errors
pub suberror SchemaError {
  JsonDecodeError(@json.JsonDecodeError)
  JsonPointerDecodeError(String)
}

///|
/// Runtime errors during validation
pub suberror RuntimeError {
  Unsupported(String)
}
