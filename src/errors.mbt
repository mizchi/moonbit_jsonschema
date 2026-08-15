///|
/// JsonSchema compilation errors
pub suberror ParseError {
  JsonDecodeError(@json.JsonDecodeError)
  PointerParseError(String)
  InvalidSchema(String)
}

///|
pub struct ValidationError {
  input : Json
  json_path : JsonPointer
  schema_path : JsonPointer
  message : String
  children : Array[ValidationError]?
} derive(Eq)

///|
pub impl Show for ValidationError with output(self, logger) {
  logger.write_string("{input: ")
  self.input.output(logger)
  logger.write_string(", json_path: ")
  self.json_path.output(logger)
  logger.write_string(", schema_path: ")
  self.schema_path.output(logger)
  logger.write_string(", message: ")
  self.message.output(logger)
  logger.write_string(", children: ")
  self.children.output(logger)
  logger.write_string("}")
}

///|
pub fn ValidationError::new(
  input : Json,
  json_path : JsonPointer,
  schema_path : JsonPointer,
  message : String,
  children? : Array[ValidationError],
) -> ValidationError {
  ValidationError::{ input, json_path, schema_path, message, children }
}
