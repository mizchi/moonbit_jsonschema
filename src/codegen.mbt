///|
fn generate_code(
  schema : JsonSchema,
  logger? : StringBuilder = StringBuilder::new(),
) -> String {
  match schema {
    JsonSchema::Object(properties~, ..) => {
      logger.write_string("struct MyStruct {\n")
      if properties is Some(properties) {
        for key, subschema in properties {
          logger.write_string(
            "  " + key + " : " + generate_code(subschema) + "\n",
          )
        }
      }
      logger.write_string("} derive(Show, FromJson, ToJson) \n")
      return logger.to_string()
    }
    JsonSchema::String(..) => "String"
    JsonSchema::Number(..) => "Double"
    // JsonSchema::Integer { .. } => "42".to_string(),
    // JsonSchema::Boolean { .. } => "true".to_string(),
    // JsonSchema::Array { items, .. } => {
    //   let item_code = generate_code(*items);
    //   format!("[{}, {}]", item_code, item_code)
    // }
    // JsonSchema::Null { .. } => "null".to_string(),
    _ => "\"unsupported type\"".to_string()
  }
}

///|
test "code generation" {
  let schema : Json = @json.parse(
    (
      #|{
      #|  "type": "object",
      #|  "properties": {
      #|    "name": { "type": "string" },
      #|    "age": { "type": "number" }
      #|  },
      #|  "required": ["name", "age"]
      #|}
    ),
  )
  let jschema : JsonSchema = @json.from_json(schema)
  let code = generate_code(jschema)
  inspect(
    code,
    content=(
      #|struct MyStruct {
      #|  name : String
      #|  age : Double
      #|} derive(Show, FromJson, ToJson) 
      #|

    ),
  )
}
