///|
pub struct ObjectConstraints {
  properties : Map[String, JsonSchema]?
  required : Array[String]?
  additional_properties : JsonSchema?
} derive (
  Show,
  Eq,
  FromJson(
    fields(
      additional_properties(rename="additionalProperties"),
      pattern_properties(rename="patternProperties"),
      property_names(rename="propertyNames"),
    ),
  ),
  ToJson(
    fields(
      additional_properties(rename="additionalProperties"),
      pattern_properties(rename="patternProperties"),
    ),
  ),
)
