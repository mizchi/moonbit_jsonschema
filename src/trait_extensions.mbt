///|
/// Explicitly expose schema trait methods as type methods.
extend AnySchema with JsonSchemaSerializable::{to_json_schema}

///|
extend AnySchema with Validatable::{validate}

///|
extend NullSchema with JsonSchemaSerializable::{to_json_schema}

///|
extend NullSchema with Validatable::{validate}

///|
extend BooleanSchema with JsonSchemaSerializable::{to_json_schema}

///|
extend BooleanSchema with Validatable::{validate}

///|
extend StringSchema with JsonSchemaSerializable::{to_json_schema, parse}

///|
extend StringSchema with Validatable::{validate}

///|
extend NumberSchema with JsonSchemaSerializable::{to_json_schema}

///|
extend NumberSchema with Validatable::{validate}

///|
extend IntegerSchema with JsonSchemaSerializable::{to_json_schema}

///|
extend IntegerSchema with Validatable::{validate}

///|
extend ArraySchema with JsonSchemaSerializable::{to_json_schema}

///|
extend ArraySchema with Validatable::{validate}

///|
extend ObjectSchema with JsonSchemaSerializable::{to_json_schema}

///|
extend ObjectSchema with Validatable::{validate}

///|
extend AnyOfSchema with JsonSchemaSerializable::{to_json_schema}

///|
extend AnyOfSchema with Validatable::{validate}

///|
extend AllOfSchema with JsonSchemaSerializable::{to_json_schema}

///|
extend AllOfSchema with Validatable::{validate}

///|
extend OneOfSchema with JsonSchemaSerializable::{to_json_schema}

///|
extend OneOfSchema with Validatable::{validate}

///|
extend RefSchema with JsonSchemaSerializable::{to_json_schema, parse}

///|
extend RefSchema with Validatable::{validate}

///|
extend EnumSchema with JsonSchemaSerializable::{to_json_schema}

///|
extend EnumSchema with Validatable::{validate}

///|
extend ConstSchema with JsonSchemaSerializable::{to_json_schema}

///|
extend ConstSchema with Validatable::{validate}
