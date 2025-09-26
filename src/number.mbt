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
  ToJson(
    fields(
      exclusive_minimum(rename="exclusiveMinimum"),
      exclusive_maximum(rename="exclusiveMaximum"),
      multiple_of(rename="multipleOf"),
    ),
  ),
  FromJson(
    fields(
      exclusive_minimum(rename="exclusiveMinimum"),
      exclusive_maximum(rename="exclusiveMaximum"),
      multiple_of(rename="multipleOf"),
    ),
  ),
)
