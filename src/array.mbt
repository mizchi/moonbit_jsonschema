///|
pub struct ArrayConstraint {
  items : JsonSchema?
  prefixItems : Array[JsonSchema]?
  contains : JsonSchema?
  minContains : Int?
  maxContains : Int?
  minItems : Int?
  maxItems : Int?
  uniqueItems : Bool?
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
      unique_items(rename="uniqueItems"),
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
      unique_items(rename="uniqueItems"),
    ),
  ),
)
