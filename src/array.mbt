///|
pub struct ArrayConstraint {
  items : JsonSchema?
  prefix_items : Array[JsonSchema]?
  contains : JsonSchema?
  min_contains : Int?
  max_contains : Int?
  min_items : Int?
  max_items : Int?
} derive (
  Show,
  Eq,
  FromJson(
    fields(
      items(rename="items"),
      prefix_items(rename="prefixItems"),
      contains(rename="contains"),
      min_contains(rename="minContains"),
      max_contains(rename="maxContains"),
      min_items(rename="minItems"),
      max_items(rename="maxItems"),
    ),
  ),
  ToJson(
    fields(
      items(rename="items"),
      prefix_items(rename="prefixItems"),
      contains(rename="contains"),
      min_contains(rename="minContains"),
      max_contains(rename="maxContains"),
      min_items(rename="minItems"),
      max_items(rename="maxItems"),
    ),
  ),
)
