// TODO: raise error

///|
/// wip rename
trait Validatable {
  from_json_schema(Json) -> Result[JsonSchema, String]
  to_json_schema(Self) -> Json
  validate(
    Self,
    Json,
    Resolver,
    json_path~ : JsonPointer,
    schema_path~ : JsonPointer,
  ) -> Array[ValidationError]
}
// priv struct TestSchema {
// } derive(Show, Eq)

// impl Validatable for TestSchema with to_json_schema(self) {
// }
// impl Validatable for TestSchema with from_json_schema(json) {
//   try {
//     let v : TestSchema = @json.from_json(json)
//     v |> JsonSchema::Test|> Ok
//   } catch {
//     _ => Err("Failed to parse TestSchema".to_string())
//   }
// }
