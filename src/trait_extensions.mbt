///|
/// Explicitly expose validation as a type method for schema implementations.
extend AnySchema with Validatable::{validate}

///|
extend NullSchema with Validatable::{validate}

///|
extend BooleanSchema with Validatable::{validate}

///|
extend StringSchema with Validatable::{validate}

///|
extend NumberSchema with Validatable::{validate}

///|
extend IntegerSchema with Validatable::{validate}

///|
extend ArraySchema with Validatable::{validate}

///|
extend ObjectSchema with Validatable::{validate}

///|
extend AnyOfSchema with Validatable::{validate}

///|
extend AllOfSchema with Validatable::{validate}

///|
extend OneOfSchema with Validatable::{validate}

///|
extend RefSchema with Validatable::{validate}

///|
extend EnumSchema with Validatable::{validate}

///|
extend ConstSchema with Validatable::{validate}
