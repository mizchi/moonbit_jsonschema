///|
suberror UnsuppotedSchemaError String

///|
pub struct Validator {
  schema : Schema
  priv resolver : (String) -> Schema?
}

///|
pub fn Validator::from_json(
  jsonschema : Json,
) -> Validator raise UnsuppotedSchemaError {
  let schema : Schema = @json.from_json(jsonschema) catch {
    err => raise UnsuppotedSchemaError(err.to_string())
  }
  let resolver = fn(ref_expr : String) -> Schema? {
    let object_path = ObjectPath::from_json_pointer(ref_expr) catch {
      _err => return None
    }
    match object_path.access(jsonschema) {
      Some(json) =>
        try {
          let schema : Schema = @json.from_json(json)
          Some(schema)
        } catch {
          _err => None
        }
      None => None
    }
  }
  Validator::{ schema, resolver }
}

///|
pub fn Validator::with_resolver(
  schema : Schema,
  resolver : (String) -> Schema?,
) -> Validator {
  Validator::{ schema, resolver }
}

///|
pub fn Validator::validate(
  self : Validator,
  input : Json,
) -> Result[Unit, Array[ValidationError]] raise UnsuppotedSchemaError {
  let errors = self.schema.validate_inner(input, resolver=self.resolver)
  if errors.length() == 0 {
    Ok(())
  } else {
    Err(errors)
  }
}

///|
pub fn Schema::validate(
  self : Schema,
  value : Json,
) -> Result[Unit, Array[ValidationError]] raise UnsuppotedSchemaError {
  let resolver = fn(ref_expr : String) -> Schema? {
    let object_path = ObjectPath::from_json_pointer(ref_expr) catch {
      _err => return None
    }
    match object_path.access(value) {
      Some(json) =>
        try {
          let schema : Schema = @json.from_json(json)
          Some(schema)
        } catch {
          _err => None
        }
      None => None
    }
  }
  match self.validate_inner(value, resolver~) {
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
  resolver~ : (String) -> Schema?,
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
    Const(expected) =>
      if value != expected {
        [
          ValidationError::new(
            json_path,
            schema_path,
            "\{value} does not match constant value \{expected}",
          ),
        ]
      } else {
        []
      }
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
              children: None,
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
              resolver~,
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
            resolver~,
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
    Ref(ref_expr) =>
      match resolver(ref_expr) {
        Some(resolved_schema) => {
          // let opath = ObjectPath::from_json_pointer(ref_expr)
          let errors = resolved_schema.validate_inner(
            value,
            json_path~,
            // TODO: fix schema_path to reference path
            schema_path=schema_path.add_key("$ref"),
            resolver~,
          )
          errors
        }
        None =>
          [
            ValidationError::new(
              json_path,
              schema_path.add_key("$ref"),
              "Failed to resolve reference '\{ref_expr}'",
            ),
          ]
      }
    Not(_schema) =>
      raise UnsuppotedSchemaError("not schema validation not implemented")
    AllOf(schemas) => {
      let errors : Array[ValidationError] = []
      let mut passed = 0
      for idx, schema in schemas {
        let sub_errors = schema.validate_inner(
          value,
          json_path~,
          schema_path=schema_path.add_key("oneOf").add_index(idx),
          resolver~,
        )
        if sub_errors.length() == 0 {
          passed += 1
        } else {
          errors.append(sub_errors)
        }
      }
      if passed == schemas.length() {
        []
      } else {
        errors.push(
          ValidationError::new(
            json_path,
            schema_path.add_key("allOf"),
            "\{value} does not match exactly one schema in allOf",
          ),
        )
        errors
      }
    }
    OneOf(schemas) => {
      let errors : Array[ValidationError] = []
      let mut passed = 0
      for idx, schema in schemas {
        let sub_errors = schema.validate_inner(
          value,
          json_path~,
          schema_path=schema_path.add_key("oneOf").add_index(idx),
          resolver~,
        )
        if sub_errors.length() == 0 {
          passed += 1
        } else {
          errors.append(sub_errors)
        }
      }
      if passed == 1 {
        []
      } else {
        errors.push(
          ValidationError::new(
            json_path,
            schema_path.add_key("oneOf"),
            "\{value} does not match exactly one schema in oneOf",
          ),
        )
        errors
      }
    }
    AnyOf(schemas) => {
      let errors : Array[ValidationError] = []
      let mut passed = 0
      for idx, schema in schemas {
        let sub_errors = schema.validate_inner(
          value,
          json_path~,
          schema_path=schema_path.add_key("anyOf").add_index(idx),
          resolver~,
        )
        if sub_errors.length() == 0 {
          passed += 1
        } else {
          errors.append(sub_errors)
        }
      }
      if passed > 0 {
        []
      } else {
        errors.push(
          ValidationError::new(
            json_path,
            schema_path.add_key("anyOf"),
            "\{value} does not match any schema in anyOf",
          ),
        )
        errors
      }
    }
    _ => {
      println("Schema variant not implemented yet: \{self}")
      panic()
    }
  }
}

///|
pub struct ValidationError {
  json_path : ObjectPath
  schema_path : ObjectPath
  message : String
  children : Array[ValidationError]?
} derive(Show)

///|
pub fn ValidationError::new(
  json_path : ObjectPath,
  schema_path : ObjectPath,
  message : String,
  children? : Array[ValidationError],
) -> ValidationError {
  ValidationError::{ json_path, schema_path, message, children }
}
