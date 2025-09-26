// TODO: raise error

///|
/// wip rename
trait Validatable {
  from_json_schema(Json) -> Result[JsonSchema, String]
  to_json_schema(Self) -> Json
  validate(Self, Json, json_path~ : JsonPointer, schema_path~ : JsonPointer) -> Array[
    ValidationError,
  ]
}
