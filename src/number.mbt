///|
pub struct NumberConstraint {
  minimum : Double?
  maximum : Double?
  exclusive_minimum : Double?
  exclusive_maximum : Double?
  // multipleOf : Double?
} derive (
  Show,
  Eq,
  // FromJson(fields(exclusiveMinimum(rename="exclusiveMinimum"), exclusiveMaximum(rename="exclusiveMaximum"), multipleOf(rename="multipleOf"))),
  ToJson(
    fields(
      exclusiveMinimum(rename="exclusiveMinimum"),
      exclusiveMaximum(rename="exclusiveMaximum"),
      multiple_of(rename="multipleOf"),
    ),
  ),
  FromJson(
    fields(
      exclusiveMinimum(rename="exclusiveMinimum"),
      exclusiveMaximum(rename="exclusiveMaximum"),
      multiple_of(rename="multipleOf"),
    ),
  ),
)
