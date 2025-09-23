///|
/// Example:
/// ```
/// let jsonschema : Json = { "type": "string" }
/// let validator = build_validator(jsonschema)
/// let _result = validator.validate("hello")
/// ```
pub fn build_validator(root_json : Json) -> Validator raise ParseError {
  let schema : JsonSchema = @json.from_json(root_json) catch {
    err => raise ParseError::JsonDecodeError(err)
  }
  let resolver = build_resolver(root_json)
  Validator::{ schema, resolver }
}

///|
struct Validator {
  schema : JsonSchema
  resolver : (String) -> JsonSchema?
}

///|
pub fn Validator::with_resolver(
  schema : JsonSchema,
  resolver : (String) -> JsonSchema?,
) -> Validator {
  Validator::{ schema, resolver }
}

///|
pub fn Validator::validate(
  self : Validator,
  input : Json,
) -> Result[Unit, Array[ValidationError]] raise RuntimeError {
  let errors = self.schema.validate_internal(input, resolver=self.resolver)
  if errors.length() == 0 {
    Ok(())
  } else {
    Err(errors)
  }
}

///|
/// internal validator for schema
pub fn JsonSchema::validate(
  self : JsonSchema,
  value : Json,
) -> Result[Unit, Array[ValidationError]] raise Error {
  let resolver = fn(_ref_expr : String) -> JsonSchema? { None }
  match self.validate_internal(value, resolver~) {
    [] => Ok(())
    errors => Err(errors)
  }
}

///|
fn JsonSchema::validate_internal(
  self : JsonSchema,
  value : Json,
  resolver~ : (String) -> JsonSchema?,
  json_path? : JsonPointer = JsonPointer::Root,
  schema_path? : JsonPointer = JsonPointer::Root,
) -> Array[ValidationError] raise RuntimeError {
  match self {
    Boolean(_) =>
      match value {
        @json.True => []
        @json.False => []
        _ =>
          [
            ValidationError::new(
              value, json_path, schema_path, "Value is not a boolean",
            ),
          ]
      }
    Null(_) =>
      match value {
        @json.Null => []
        _ =>
          [
            ValidationError::new(
              value, json_path, schema_path, "Value is not null",
            ),
          ]
      }
    Any(_) => []
    Const(expected) =>
      if value != expected {
        [
          ValidationError::new(
            value,
            json_path,
            schema_path,
            "Value does not match constant value \{expected}",
          ),
        ]
      } else {
        []
      }
    Integer(minimum~, maximum~, exclusiveMaximum~, exclusiveMinimum~, ..) => {
      guard value is @json.Number(input, ..) else {
        return [
          ValidationError::new(
            value, json_path, schema_path, "Value is not a number",
          ),
        ]
      }
      if input.floor() != input {
        return [
          ValidationError::new(
            value, json_path, schema_path, "Value is not an integer",
          ),
        ]
      }
      let input = input.to_int()
      let errors : Array[ValidationError] = []
      if minimum is Some(min) && input < min {
        errors.push(
          ValidationError::new(
            value,
            json_path,
            schema_path.key("minimum"),
            "Value is less than minimum \{min}",
          ),
        )
      }
      if maximum is Some(max) && input > max {
        errors.push(
          ValidationError::new(
            value,
            json_path,
            schema_path.key("maximum"),
            "Value is greater than maximum \{max}",
          ),
        )
      }
      if exclusiveMaximum is Some(max) && input >= max {
        errors.push(
          ValidationError::new(
            value,
            json_path,
            schema_path.key("exclusiveMaximum"),
            "Value is not less than exclusive maximum \{max}",
          ),
        )
      }
      if exclusiveMinimum is Some(min) && input <= min {
        errors.push(
          ValidationError::new(
            value,
            json_path,
            schema_path.key("exclusiveMinimum"),
            "Value is not greater than exclusive minimum \{min}",
          ),
        )
      }
      errors
    }
    Number(minimum~, maximum~, exclusiveMaximum~, exclusiveMinimum~, ..) => {
      guard value is @json.Number(input, ..) else {
        return [
          ValidationError::new(
            value, json_path, schema_path, "Value is not a number",
          ),
        ]
      }
      let errors : Array[ValidationError] = []
      if minimum is Some(min) && input < min {
        errors.push(
          ValidationError::new(
            value,
            json_path,
            schema_path.key("minimum"),
            "Value is less than minimum \{min}",
          ),
        )
      }
      if maximum is Some(max) && input > max {
        errors.push(
          ValidationError::new(
            value,
            json_path,
            schema_path.key("maximum"),
            "Value is greater than maximum \{max}",
          ),
        )
      }
      if exclusiveMaximum is Some(max) && input >= max {
        errors.push(
          ValidationError::new(
            value,
            json_path,
            schema_path.key("exclusiveMaximum"),
            "\{input} is not less than exclusive maximum \{max}",
          ),
        )
      }
      if exclusiveMinimum is Some(min) && input <= min {
        errors.push(
          ValidationError::new(
            value,
            json_path,
            schema_path.key("exclusiveMinimum"),
            "Value is not greater than exclusive minimum \{min}",
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
                value, json_path, schema_path, "Value is not a string",
              ),
            ]
          }
          let len = input.length()
          if minLength is Some(min) && len < min {
            return [
              ValidationError::new(
                value,
                json_path,
                schema_path.key("minLength"),
                "String length \{len} is less than minimum \{min}",
              ),
            ]
          }
          if maxLength is Some(max) && len > max {
            return [
              ValidationError::new(
                value,
                json_path,
                schema_path.key("maxLength"),
                "String length \{len} is greater than maximum \{max}",
              ),
            ]
          }
          if enum_ is Some(enum_values) && !enum_values.contains(input) {
            return [
              ValidationError::new(
                value,
                json_path,
                schema_path.key("enum"),
                "\{input} is not in \{enum_values}",
              ),
            ]
          }
          []
        }
        _ =>
          [
            ValidationError::new(
              value, json_path, schema_path, "Value is not a string",
            ),
          ]
      }
    Array(minItems~, maxItems~, items~, ..) => {
      guard value is @json.Array(array) else {
        return [
          ValidationError::new(
            value, json_path, schema_path, "Value is not an array",
          ),
        ]
      }
      let errors : Array[ValidationError] = []
      let len = array.length()

      // Min items
      if minItems is Some(min) && len < min {
        errors.push(
          ValidationError::new(
            value,
            json_path,
            schema_path.key("minItems"),
            "Array length \{len} is less than minimum \{min}",
          ),
        )
      }

      // Max items
      if maxItems is Some(max) && len > max {
        errors.push(
          ValidationError::new(
            value,
            json_path,
            schema_path.key("maxItems"),
            "Array length \{len} is greater than maximum \{max}",
          ),
        )
      }
      if items is Some(item_schema) {
        for i, item in array {
          errors.append(
            item_schema.validate_internal(
              item,
              json_path=json_path.index(i),
              schema_path=schema_path.key("items"),
              resolver~,
            ),
          )
        }
      }
      errors
    }
    Object(properties~, required~, additionalProperties~, ..) => {
      guard value is @json.Object(obj) else {
        return [
          ValidationError::new(
            value,
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
              value,
              json_path.key(key),
              schema_path.key("required"),
              "Required property '\{key}' is missing",
            ),
          )
        }
      }
      // TODO: {type: string}
      let required_keys = match required {
        Some(keys) => Set::from_array(keys)
        None => Set::new()
      }
      let props_keys = match properties {
        Some(props) => props.keys() |> Set::from_iter
        None => Set::new()
      }
      let additional_props = obj
        .keys()
        .filter(fn(key) {
          !required_keys.contains(key) && !props_keys.contains(key)
        })
        |> Set::from_iter
      if additionalProperties is Some(schema) {
        for key in additional_props {
          guard obj.get(key) is Some(child_value) else { continue }
          let child_errors = schema.validate_internal(
            child_value,
            json_path=json_path.key(key),
            schema_path=schema_path.key("additionalProperties"),
            resolver~,
          )
          errors.append(child_errors)
        }
      } else if additional_props.size() > 0 {
        for key in additional_props {
          errors.push(
            ValidationError::new(
              value,
              json_path.key(key),
              schema_path.key("additionalProperties"),
              "Additional property '\{additional_props}' is not allowed",
            ),
          )
        }
      }
      // Properties validation
      if properties is Some(props) {
        props.each(fn(prop_name, child_schema) {
          guard obj.get(prop_name) is Some(child_value) else { return }
          let child_errors = child_schema.validate_internal(
            child_value,
            json_path=json_path.key(prop_name),
            schema_path=schema_path.key("properties").key(prop_name),
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
            value,
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
          let errors = resolved_schema.validate_internal(
            value,
            json_path~,
            // TODO: fix schema_path to reference path
            schema_path=schema_path.key("$ref"),
            resolver~,
          )
          errors
        }
        None =>
          [
            ValidationError::new(
              value,
              json_path,
              schema_path.key("$ref"),
              "Failed to resolve reference '\{ref_expr}'",
            ),
          ]
      }
    Not(_schema) =>
      raise RuntimeError::Unsupported("not schema validation not implemented")
    AllOf(schemas) => {
      let errors : Array[ValidationError] = []
      let mut passed = 0
      for idx, schema in schemas {
        let sub_errors = schema.validate_internal(
          value,
          json_path~,
          schema_path=schema_path.key("oneOf").index(idx),
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
            value,
            json_path,
            schema_path.key("allOf"),
            "Value does not match exactly one schema in allOf",
          ),
        )
        errors
      }
    }
    OneOf(schemas) => {
      let errors : Array[ValidationError] = []
      let mut passed = 0
      for idx, schema in schemas {
        let sub_errors = schema.validate_internal(
          value,
          json_path~,
          schema_path=schema_path.key("oneOf").index(idx),
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
            value,
            json_path,
            schema_path.key("oneOf"),
            "Value does not match exactly one schema in oneOf",
          ),
        )
        errors
      }
    }
    AnyOf(schemas) => {
      let errors : Array[ValidationError] = []
      let mut passed = 0
      for idx, schema in schemas {
        let sub_errors = schema.validate_internal(
          value,
          json_path~,
          schema_path=schema_path.key("anyOf").index(idx),
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
            value,
            json_path,
            schema_path.key("anyOf"),
            "Value does not match any schema in anyOf",
          ),
        )
        errors
      }
    }
  }
}

///|
pub struct ValidationError {
  input : Json
  json_path : JsonPointer
  schema_path : JsonPointer
  message : String
  children : Array[ValidationError]?
} derive(Show, Eq)

///|
pub fn ValidationError::new(
  input : Json,
  json_path : JsonPointer,
  schema_path : JsonPointer,
  message : String,
  children? : Array[ValidationError],
) -> ValidationError {
  ValidationError::{ input, json_path, schema_path, message, children }
}
