///|
suberror UnsuppotedSchemaError String

///|
pub fn Schema::validate(
  self : Schema,
  value : Json,
) -> Result[Unit, Array[ValidationError]] raise UnsuppotedSchemaError {
  match self.validate_inner(value) {
    [] => Ok(())
    errors => Err(errors)
  }
}

///|
fn Schema::validate_inner(
  self : Schema,
  value : Json,
  json_path? : ObjectPath = ObjectPath::Root,
  schema_path? : ObjectPath = ObjectPath::Root,
) -> Array[ValidationError] raise UnsuppotedSchemaError {
  match self {
    Boolean =>
      match value {
        @json.True => []
        @json.False => []
        _ =>
          [
            ValidationError::new(
              json_path,
              schema_path,
              "\{value} is not a boolean",
            ),
          ]
      }
    Null =>
      match value {
        @json.Null => []
        _ =>
          [ValidationError::new(json_path, schema_path, "\{value} is not null")]
      }
    Any => []
    Integer(minimum~, maximum~, ..) => {
      guard value is @json.Number(input, ..) else {
        return [
          ValidationError::new(
            json_path,
            schema_path,
            "\{value} is not a number",
          ),
        ]
      }
      if input.floor() != input {
        return [
          ValidationError::new(
            json_path,
            schema_path,
            "\{input} is not an integer",
          ),
        ]
      }
      let input = input.to_int()
      let errors : Array[ValidationError] = []
      if minimum is Some(min) && input < min {
        errors.push(
          ValidationError::new(
            json_path,
            schema_path.add_key("minimum"),
            "\{input} is less than minimum \{min}",
          ),
        )
      }
      if maximum is Some(max) && input > max {
        errors.push(
          ValidationError::new(
            json_path,
            schema_path.add_key("maximum"),
            "\{input} is greater than maximum \{max}",
          ),
        )
      }
      errors
    }
    Number(minimum~, maximum~, ..) => {
      guard value is @json.Number(input, ..) else {
        return [
          ValidationError::new(json_path, schema_path, "Value is not a number"),
        ]
      }
      let errors : Array[ValidationError] = []
      if minimum is Some(min) && input < min {
        errors.push(
          ValidationError::new(
            json_path,
            schema_path.add_key("minimum"),
            "\{input} is less than minimum \{min}",
          ),
        )
      }
      if maximum is Some(max) && input > max {
        errors.push(
          ValidationError::new(
            json_path,
            schema_path.add_key("maximum"),
            "\{input} is greater than maximum \{max}",
          ),
        )
      }
      errors
    }
    String(minLength~, maxLength~, enum_~, ..) =>
      match value {
        // TODO: validate string constraints
        @json.String(_) => {
          guard value is @json.String(input) else {
            return [
              ValidationError::new(
                json_path, schema_path, "Value is not a string",
              ),
            ]
          }
          let len = input.length()
          if minLength is Some(min) && len < min {
            return [
              ValidationError::new(
                json_path,
                schema_path.add_key("minLength"),
                "String length \{len} is less than minimum \{min}",
              ),
            ]
          }
          if maxLength is Some(max) && len > max {
            return [
              ValidationError::new(
                json_path,
                schema_path.add_key("maxLength"),
                "String length \{len} is greater than maximum \{max}",
              ),
            ]
          }
          if enum_ is Some(enum_values) && !enum_values.contains(input) {
            return [
              ValidationError::new(
                json_path,
                schema_path.add_key("enum"),
                "\{input} is not in \{enum_values}",
              ),
            ]
          }
          []
        }
        _ =>
          [
            ValidationError::{
              json_path,
              schema_path,
              message: "\{value} is not a string",
            },
          ]
      }
    Array(minItems~, maxItems~, items~, ..) => {
      guard value is @json.Array(array) else {
        return [
          ValidationError::new(json_path, schema_path, "Value is not an array"),
        ]
      }
      let errors : Array[ValidationError] = []
      let len = array.length()

      // Min items
      if minItems is Some(min) && len < min {
        errors.push(
          ValidationError::new(
            json_path,
            schema_path.add_key("minItems"),
            "Array length \{len} is less than minimum \{min}",
          ),
        )
      }

      // Max items
      if maxItems is Some(max) && len > max {
        errors.push(
          ValidationError::new(
            json_path,
            schema_path.add_key("maxItems"),
            "Array length \{len} is greater than maximum \{max}",
          ),
        )
      }
      if items is Some(item_schema) {
        for i, item in array {
          errors.append(
            item_schema.validate_inner(
              item,
              json_path=json_path.add_index(i),
              schema_path=schema_path.add_key("items"),
            ),
          )
        }
      }

      // Prefix items validation (2020-12)
      // match constraints.prefixItems {
      //   Some(prefix_schemas) => {
      //     let prefix_len = prefix_schemas.length()
      //     for i = 0; i < len && i < prefix_len; i = i + 1 {
      //       let item_path = path + "[\{i}]"
      //       errors.append(
      //         validate_value(
      //           value[i],
      //           prefix_schemas[i],
      //           item_path,
      //           schema_path + "/prefixItems[\{i}]",
      //         ),
      //       )
      //     }
      //     // Items beyond prefix are validated by items schema
      //     match constraints.items {
      //       Some(item_schema) =>
      //         for i = prefix_len; i < len; i = i + 1 {
      //           let item_path = path + "[\{i}]"
      //           errors.append(
      //             validate_value(
      //               value[i],
      //               item_schema,
      //               item_path,
      //               schema_path + "/items",
      //             ),
      //           )
      //         }
      //       None => ()
      //     }
      //   }
      //   None =>
      //     // Items validation (no prefix)
      //     match constraints.items {
      //       Some(item_schema) =>
      //         for i = 0; i < len; i = i + 1 {
      //           let item_path = path + "[\{i}]"
      //           errors.append(
      //             validate_value(
      //               value[i],
      //               item_schema,
      //               item_path,
      //               schema_path + "/items",
      //             ),
      //           )
      //         }
      //       None => ()
      //     }
      // }

      // Contains validation
      // match constraints.contains {
      //   Some(contains_schema) => {
      //     let mut contains_count = 0
      //     for i = 0; i < len; i = i + 1 {
      //       let sub_errors = validate_value(
      //         value[i],
      //         contains_schema,
      //         path + "[\{i}]",
      //         schema_path + "/contains",
      //       )
      //       if sub_errors.length() == 0 {
      //         contains_count = contains_count + 1
      //       }
      //     }

      //     // Check minContains
      //     match constraints.minContains {
      //       Some(min) =>
      //         if contains_count < min {
      //           errors.push(
      //             ValidationError::new(
      //               format_path(path),
      //               "Array contains only \{contains_count} matching items, less than minimum \{min}",
      //               schema_path + "/minContains",
      //             ),
      //           )
      //         }
      //       None =>
      //         // Default minContains is 1 if contains is present
      //         if contains_count < 1 {
      //           errors.push(
      //             ValidationError::new(
      //               format_path(path),
      //               "Array does not contain any item matching the schema",
      //               schema_path + "/contains",
      //             ),
      //           )
      //         }
      //     }

      //     // Check maxContains
      //     match constraints.maxContains {
      //       Some(max) =>
      //         if contains_count > max {
      //           errors.push(
      //             ValidationError::new(
      //               format_path(path),
      //               "Array contains \{contains_count} matching items, more than maximum \{max}",
      //               schema_path + "/maxContains",
      //             ),
      //           )
      //         }
      //       None => ()
      //     }
      //   }
      //   None => ()
      // }
      errors
    }
    Object(properties~, required~, additionalProperties~, ..) => {
      guard value is @json.Object(obj) else {
        return [
          ValidationError::new(
            json_path,
            schema_path,
            "\{value} is not an object",
          ),
        ]
      }
      // Required properties
      let errors : Array[ValidationError] = []

      // let required_keys: Array[String] = []
      if required is Some(required_keys) {
        let non_exsited_keys = required_keys.filter(fn(key) {
          !obj.contains(key)
        })
        for key in non_exsited_keys {
          errors.push(
            ValidationError::new(
              json_path.add_key(key),
              schema_path.add_key("required"),
              "Required property '\{key}' is missing",
            ),
          )
        }
      }
      if additionalProperties is Some(schema_or_bool) {
        let _ = match schema_or_bool {
          Json::Object(_) =>
            raise UnsuppotedSchemaError(
              "additionalProperties as schema is not implemented yet",
            )
          Json::False => {
            // TODO: {type: string}
            let required_keys = match required {
              Some(keys) => keys
              None => []
            }
            let props_keys = match properties {
              Some(props) => props.keys().to_array()
              None => []
            }
            let additional_props : Array[String] = obj
              .keys()
              .filter(fn(key) {
                !required_keys.contains(key) && !props_keys.contains(key)
              })
              .to_array()
            if additional_props.length() > 0 {
              for key in additional_props {
                errors.push(
                  ValidationError::new(
                    json_path.add_key(key),
                    schema_path.add_key("additionalProperties"),
                    "Additional property '\{additional_props}' is not allowed",
                  ),
                )
              }
            }
          }
          _ => ()
        }

      }
      // Properties validation
      if properties is Some(props) {
        props.each(fn(prop_name, child_schema) {
          guard obj.get(prop_name) is Some(child_value) else { return }
          let child_errors = child_schema.validate_inner(
            child_value,
            json_path=json_path.add_key(prop_name),
            schema_path=schema_path.add_key("properties").add_key(prop_name),
          )
          errors.append(child_errors)
        })
        // No properties to validate
      }
      errors
    }
    Enum(enum_values) =>
      if !enum_values.contains(value) {
        [
          ValidationError::new(
            json_path,
            schema_path,
            "\{value} is not in \{enum_values}",
          ),
        ]
      } else {
        []
      }
    Ref(_ref) => raise UnsuppotedSchemaError("$ref not implemented")
    Not(_schema) =>
      raise UnsuppotedSchemaError("not schema validation not implemented")
    AnyOf(_schemas) =>
      raise UnsuppotedSchemaError("anyOf schema validation not implemented")
    AllOf(_schemas) =>
      raise UnsuppotedSchemaError("allOf schema validation not implemented")
    OneOf(_schemas) =>
      raise UnsuppotedSchemaError("oneOf schema validation not implemented")
    _ => {
      // TODO
      println("Schema variant not implemented yet: \{self}")
      panic()
    }
    // Ref(_) => {
    //   println("Reference resolution not implemented")
    //   panic()
    // }
    // Not(_) => ...
    // OneOf(_) => ...
    // AllOf(_) => ...
    // AnyOf(_) => ...
    // Const(_) => ...
    // Enum(_) => ...
    // If(_) => ...

    // Multiple(_) => ...
  }
  // let validator = Validator::new(self)
  // validator.validate(value)
}

///|
pub struct ValidationError {
  json_path : ObjectPath
  schema_path : ObjectPath
  message : String
} derive(Show)

///|
pub fn ValidationError::new(
  json_path : ObjectPath,
  schema_path : ObjectPath,
  message : String,
) -> ValidationError {
  ValidationError::{ json_path, schema_path, message }
}
