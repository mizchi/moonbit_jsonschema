///|
fn generate_typescript(schema : JsonSchema) -> String {
  match schema {
    JsonSchema::Object(properties~, ..) => {
      let logger = StringBuilder::new()
      logger.write_string("export type MyStruct = {\n")
      if properties is Some(properties) {
        let required_keys = match schema {
          JsonSchema::Object(required~, ..) =>
            match required {
              Some(req) => req |> Set::from_array
              None => Set::new()
            }
          _ => Set::new()
        }
        for key, subschema in properties {
          let key_is_required = required_keys.contains(key)
          if key_is_required {
            logger.write_string("  \{key}: ")
          } else {
            logger.write_string("  \{key}?: ")
          }
          let subtype = generate_typescript(subschema)
          logger.write_string(subtype + ";\n")
        }
      }
      logger.write_string("}\n")
      return logger.to_string()
    }
    JsonSchema::String(..) => "string"
    JsonSchema::Number(..) => "number"
    JsonSchema::Integer(..) => "number"
    JsonSchema::Boolean(..) => "boolean"
    JsonSchema::OneOf(schemas) =>
      if schemas.length() == 2 {
        match schemas {
          [JsonSchema::Null(_), other] | [other, JsonSchema::Null(_)] =>
            return generate_typescript(other) + " | null"
          _ => "any | null"
        }
      } else {
        "any | null"
      }
    JsonSchema::Array(items~, ..) =>
      "Array<" + generate_typescript(items.unwrap()) + ">"
    _ => "\"unsupported type\"".to_string()
  }
}

///|
test "ts code generation" {
  let schema : Json = @json.parse(
    (
      #|{
      #|  "type": "object",
      #|  "properties": {
      #|    "name": { "type": "string" },
      #|    "age": { "type": "number" },
      #|    "items": {
      #|      "type": "array",
      #|      "items": { "type": "string" }
      #|    },
      #|    "opt_str": {
      #|      "oneOf": [
      #|        { "type": "string" },
      #|        { "type": "null" }
      #|      ]
      #|    },
      #|    "opt_number": {
      #|      "oneOf": [
      #|        { "type": "number" },
      #|        { "type": "null" }
      #|      ]
      #|    }
      #|  },
      #|  "required": ["name", "age"]
      #|}
    ),
  )
  let jschema : JsonSchema = @json.from_json(schema)
  let code = generate_typescript(jschema)
  inspect(
    code,
    content=(
      #|export type MyStruct = {
      #|  name: string;
      #|  age: number;
      #|  items?: Array<string>;
      #|  opt_str?: string | null;
      #|  opt_number?: number | null;
      #|}
      #|
    ),
  )
}
