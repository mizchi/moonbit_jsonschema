///|
/// JsonSchema compilation errors
pub suberror SchemaParseError {
  JsonDecodeError(@json.JsonDecodeError)
  JsonPointerDecodeError(String)
}

///|
/// Runtime errors during validation
pub suberror RuntimeError {
  Unsupported(String)
}
