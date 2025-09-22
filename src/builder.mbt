// builder

///|
pub fn Schema::string(
  minLength? : Int,
  maxLength? : Int,
  pattern? : String,
  format? : String,
  enum_? : Array[String],
  contentEncoding? : String,
  contentMediaType? : String,
) -> Schema {
  Schema::String(
    minLength~,
    maxLength~,
    pattern~,
    format~,
    enum_~,
    contentEncoding~,
    contentMediaType~,
  )
}

///|
pub fn Schema::number(
  minimum? : Double,
  maximum? : Double,
  exclusiveMinimum? : Double,
  exclusiveMaximum? : Double,
  multipleOf? : Double,
) -> Schema {
  Schema::Number(
    minimum~,
    maximum~,
    exclusiveMinimum~,
    exclusiveMaximum~,
    multipleOf~,
  )
}

///|
pub fn Schema::integer(
  minimum? : Int,
  maximum? : Int,
  exclusiveMinimum? : Int,
  exclusiveMaximum? : Int,
  multipleOf? : Int,
) -> Schema {
  Schema::Integer(
    minimum~,
    maximum~,
    exclusiveMinimum~,
    exclusiveMaximum~,
    multipleOf~,
  )
}

///|
pub fn Schema::array(
  items? : Schema,
  prefixItems? : Array[Schema],
  contains? : Schema,
  minContains? : Int,
  maxContains? : Int,
  minItems? : Int,
  maxItems? : Int,
  uniqueItems? : Bool,
) -> Schema {
  Schema::Array(
    items~,
    prefixItems~,
    contains~,
    minContains~,
    maxContains~,
    minItems~,
    maxItems~,
    uniqueItems~,
  )
}

///|
pub fn Schema::null() -> Schema {
  Schema::Null
}

///|
pub fn Schema::boolean() -> Schema {
  Schema::Boolean
}

///|
pub fn Schema::any() -> Schema {
  Schema::Any
}

///|
pub fn Schema::object(
  properties? : Map[String, Schema],
  required? : Array[String],
  additionalProperties? : Json,
  patternProperties? : Map[String, Schema],
  propertyNames? : Schema,
  dependentSchemas? : Map[String, Schema],
  dependentRequired? : Map[String, Array[String]],
  minProperties? : Int,
  maxProperties? : Int,
) -> Schema {
  Schema::Object(
    properties~,
    required~,
    additionalProperties~,
    patternProperties~,
    propertyNames~,
    dependentSchemas~,
    dependentRequired~,
    minProperties~,
    maxProperties~,
  )
}

///|
pub fn Schema::enum_(values : Array[Json]) -> Schema {
  Schema::Enum(values)
}
