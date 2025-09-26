///|
pub struct ObjectConstraints {
  properties : Map[String, JsonSchema]?
  required : Array[String]?
  additional_properties : JsonSchema?
  // pattern_properties : Map[String, JsonSchema]?
  // property_names : JsonSchema?
  // dependent_schemas : Map[String, JsonSchema]?
  // dependent_required : Map[String, Array[String]]?
  // min_properties : Int?
  // max_properties : Int?
  // description : String?
} derive (
  Show,
  Eq,
  FromJson(
    fields(
      additional_properties(rename="additionalProperties"),
      pattern_properties(rename="patternProperties"),
      property_names(rename="propertyNames"),
      // dependent_schemas(rename="dependentSchemas"),
      // dependent_required(rename="dependentRequired"),
      // min_properties(rename="minProperties"),
      // max_properties(rename="maxProperties"),
    ),
  ),
  ToJson(
    fields(
      additional_properties(rename="additionalProperties"),
      pattern_properties(rename="patternProperties"),
      // property_names(rename="propertyNames"),
      // dependent_schemas(rename="dependentSchemas"),
      // dependent_required(rename="dependentRequired"),
      // min_properties(rename="minProperties"),
      // max_properties(rename="maxProperties"),
    ),
  ),
)
