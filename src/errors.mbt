///|
/// JsonSchema compilation errors
pub suberror ParseError {
  JsonDecodeError(@json.JsonDecodeError)
  PointerParseError(String)
}

///|
/// Runtime errors during validation
pub suberror RuntimeError {
  Unsupported(String)
}
