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
pub fn Schema::validate_inner(
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
            "Value \{input} is less than minimum \{min}",
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
      // Unique items
      // match constraints.uniqueItems {
      //   Some(unique) =>
      //     if unique {
      //       for i = 0; i < len - 1; i = i + 1 {
      //         for j = i + 1; j < len; j = j + 1 {
      //           if json_equals(value[i], value[j]) {
      //             errors.push(
      //               ValidationError::new(
      //                 format_path(path),
      //                 "Array contains duplicate items at indices \{i} and \{j}",
      //                 schema_path + "/uniqueItems",
      //               ),
      //             )
      //           }
      //         }
      //       }
      //     }
      //   None => ()
      // }

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

// Pure function that returns errors instead of mutating state

///|
// fn validate_value(
//   value : Json,
//   schema : Schema,
//   path : String,
//   schema_path : String,
// ) -> Array[ValidationError] {
//   let errors : Array[ValidationError] = []
//   match schema {
//     Schema::Enum(allowed_values) => {
//       let mut found = false
//       for i = 0; i < allowed_values.length(); i = i + 1 {
//         if json_equals(value, allowed_values[i]) {
//           found = true
//           break
//         }
//       }
//       if not(found) {
//         errors.push(
//           ValidationError::new(
//             format_path(path),
//             "Value is not in the enumeration",
//             schema_path,
//           ),
//         )
//       }
//       errors
//     }
//     Schema::Const(const_value) =>
//       if not(json_equals(value, const_value)) {
//         errors.push(
//           ValidationError::new(
//             format_path(path),
//             "Value does not match const",
//             schema_path,
//           ),
//         )
//         errors
//       } else {
//         errors
//       }
//     Schema::AnyOf(schemas) => {
//       let mut any_valid = false
//       for i = 0; i < schemas.length(); i = i + 1 {
//         let sub_errors = validate_value(
//           value,
//           schemas[i],
//           path,
//           schema_path + "/anyOf[\{i}]",
//         )
//         if sub_errors.length() == 0 {
//           any_valid = true
//           break
//         }
//       }
//       if not(any_valid) {
//         errors.push(
//           ValidationError::new(
//             format_path(path),
//             "Value does not match any schema in anyOf",
//             schema_path,
//           ),
//         )
//       }
//       errors
//     }
//     Schema::AllOf(schemas) =>
//       for i = 0; i < schemas.length(); i = i + 1 {
//         errors.append(
//           validate_value(value, schemas[i], path, schema_path + "/allOf[\{i}]"),
//         )
//       } else {
//         errors
//       }
//     Schema::OneOf(schemas) => {
//       let mut valid_count = 0
//       for i = 0; i < schemas.length(); i = i + 1 {
//         let sub_errors = validate_value(
//           value,
//           schemas[i],
//           path,
//           schema_path + "/oneOf[\{i}]",
//         )
//         if sub_errors.length() == 0 {
//           valid_count = valid_count + 1
//         }
//       }
//       if valid_count == 0 {
//         errors.push(
//           ValidationError::new(
//             format_path(path),
//             "Value does not match any schema in oneOf",
//             schema_path,
//           ),
//         )
//       } else if valid_count > 1 {
//         errors.push(
//           ValidationError::new(
//             format_path(path),
//             "Value matches multiple schemas in oneOf",
//             schema_path,
//           ),
//         )
//       }
//       errors
//     }
//     Schema::Not(not_schema) => {
//       let sub_errors = validate_value(
//         value,
//         not_schema,
//         path,
//         schema_path + "/not",
//       )
//       if sub_errors.length() == 0 {
//         errors.push(
//           ValidationError::new(
//             format_path(path),
//             "Value should not match the schema in 'not'",
//             schema_path,
//           ),
//         )
//       }
//       errors
//     }
//     Schema::If(if_schema, then_schema, else_schema) => {
//       let if_errors = validate_value(
//         value,
//         if_schema,
//         path,
//         schema_path + "/if",
//       )
//       if if_errors.length() == 0 {
//         match then_schema {
//           Some(schema) =>
//             errors.append(
//               validate_value(value, schema, path, schema_path + "/then"),
//             )
//           None => ()
//         }
//       } else {
//         match else_schema {
//           Some(schema) =>
//             errors.append(
//               validate_value(value, schema, path, schema_path + "/else"),
//             )
//           None => ()
//         }
//       }
//       errors
//     }
//   //   Schema::Ref(_ref_path) => {
//   //     // Reference resolution would be implemented here
//   //     errors.push(
//   //       ValidationError::new(
//   //         format_path(path),
//   //         "Reference resolution not implemented",
//   //         schema_path,
//   //       ),
//   //     )
//   //     errors
//   //   }
//   // }
// }

///|

///|
pub fn format_errors(errors : Array[ValidationError]) -> String {
  let mut result = "Validation failed with \{errors.length()} error(s):\n"
  for i = 0; i < errors.length(); i = i + 1 {
    let error = errors[i]
    result = result +
      "  - \{error.json_path}: \{error.message} (schema: \{error.schema_path})\n"
  }
  result
}
