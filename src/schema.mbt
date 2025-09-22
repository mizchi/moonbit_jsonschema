// JSON Schema types and definitions
// Using built-in @json.JsonValue instead of custom JsonValue type
// Schema as enum for context-aware validation

///|
pub enum Schema {
  Any
  Null
  Boolean
  String(
    minLength~ : Int?,
    maxLength~ : Int?,
    pattern~ : String?,
    format~ : String?,
    enum_~ : Array[String]?,
    contentEncoding~ : String?,
    contentMediaType~ : String?
  )
  Number(
    minimum~ : Double?,
    maximum~ : Double?,
    exclusiveMinimum~ : Double?,
    exclusiveMaximum~ : Double?,
    multipleOf~ : Double?
  )
  Integer(
    minimum~ : Int?,
    maximum~ : Int?,
    exclusiveMinimum~ : Int?,
    exclusiveMaximum~ : Int?,
    multipleOf~ : Int?
  )
  Array(
    items~ : Schema?,
    prefixItems~ : Array[Schema]?,
    contains~ : Schema?,
    minContains~ : Int?,
    maxContains~ : Int?,
    minItems~ : Int?,
    maxItems~ : Int?,
    uniqueItems~ : Bool?
  )
  Object(
    properties~ : Map[String, Schema]?,
    required~ : Array[String]?,
    additionalProperties~ : Json?,
    patternProperties~ : Map[String, Schema]?,
    propertyNames~ : Schema?,
    dependentSchemas~ : Map[String, Schema]?,
    dependentRequired~ : Map[String, Array[String]]?,
    minProperties~ : Int?,
    maxProperties~ : Int?
  )
  Enum(Array[Json])
  Const(Json)
  AnyOf(Array[Schema])
  AllOf(Array[Schema])
  OneOf(Array[Schema])
  Not(Schema)
  Ref(String)
  If(Schema, Schema?, Schema?) // if, then, else
} derive(Show)

///|
pub impl ToJson for Schema with to_json(self) -> Json {
  match self {
    Schema::String(
      minLength~,
      maxLength~,
      pattern~,
      format~,
      contentEncoding~,
      contentMediaType~,
      enum_~
    ) => {
      let json : Map[String, Json] = { "type": "string" }
      if minLength is Some(value) {
        json["minLength"] = value.to_json()
      }
      if maxLength is Some(value) {
        json["maxLength"] = value.to_json()
      }
      if pattern is Some(value) {
        json["pattern"] = value.to_json()
      }
      if format is Some(value) {
        json["format"] = value.to_json()
      }
      if contentEncoding is Some(value) {
        json["contentEncoding"] = value.to_json()
      }
      if contentMediaType is Some(value) {
        json["contentMediaType"] = value.to_json()
      }
      if enum_ is Some(values) {
        json["enum"] = values.to_json()
      }
      json.to_json()
    }
    Schema::Number(
      minimum~,
      maximum~,
      exclusiveMinimum~,
      exclusiveMaximum~,
      multipleOf~
    ) => {
      let json : Map[String, Json] = { "type": "number" }
      if minimum is Some(value) {
        json["minimum"] = value.to_json()
      }
      if maximum is Some(value) {
        json["maximum"] = value.to_json()
      }
      if exclusiveMinimum is Some(value) {
        json["exclusiveMinimum"] = value.to_json()
      }
      if exclusiveMaximum is Some(value) {
        json["exclusiveMaximum"] = value.to_json()
      }
      if multipleOf is Some(value) {
        json["multipleOf"] = value.to_json()
      }
      json.to_json()
    }
    Schema::Integer(
      minimum~,
      maximum~,
      exclusiveMinimum~,
      exclusiveMaximum~,
      multipleOf~
    ) => {
      let json : Map[String, Json] = { "type": "integer" }
      if minimum is Some(value) {
        json["minimum"] = value.to_json()
      }
      if maximum is Some(value) {
        json["maximum"] = value.to_json()
      }
      if exclusiveMinimum is Some(value) {
        json["exclusiveMinimum"] = value.to_json()
      }
      if exclusiveMaximum is Some(value) {
        json["exclusiveMaximum"] = value.to_json()
      }
      if multipleOf is Some(value) {
        json["multipleOf"] = value.to_json()
      }
      json.to_json()
    }
    _ => { "type": "unknown" }
  }
}

///|
pub impl @json.FromJson for Schema with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Schema raise {
  guard json is Json::Object(obj) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  match obj {
    { "type": "null", .. } => Schema::Null
    { "type": "boolean", .. } => Schema::Boolean
    { "type": "string", .. } => {
      let minLength = match obj.get("minLength") {
        Some(@json.Number(n, ..)) => Some(n.to_int())
        _ => None
      }
      let maxLength = match obj.get("maxLength") {
        Some(@json.Number(n, ..)) => Some(n.to_int())
        _ => None
      }
      let pattern = match obj.get("pattern") {
        Some(@json.String(p)) => Some(p)
        _ => None
      }
      let format = match obj.get("format") {
        Some(@json.String(f)) => Some(f)
        _ => None
      }
      let enum_ = match obj.get("enum") {
        Some(@json.Array(arr)) => {
          let enum_values : Array[String] = []
          for i in arr {
            match i {
              @json.String(s) => enum_values.push(s)
              _ => ()
            }
          }
          Some(enum_values)
        }
        _ => None
      }
      Schema::String(
        minLength~,
        maxLength~,
        pattern~,
        enum_~,
        format~,
        contentEncoding=None,
        contentMediaType=None,
      )
    }
    { "type": "number", .. } => {
      let minimum = match obj.get("minimum") {
        Some(@json.Number(n, ..)) => Some(n)
        _ => None
      }
      let maximum = match obj.get("maximum") {
        Some(@json.Number(n, ..)) => Some(n)
        _ => None
      }
      let exclusiveMinimum = match obj.get("exclusiveMinimum") {
        Some(@json.Number(n, ..)) => Some(n)
        _ => None
      }
      let exclusiveMaximum = match obj.get("exclusiveMaximum") {
        Some(@json.Number(n, ..)) => Some(n)
        _ => None
      }
      let multipleOf = match obj.get("multipleOf") {
        Some(@json.Number(n, ..)) => Some(n)
        _ => None
      }
      Schema::Number(
        minimum~,
        maximum~,
        exclusiveMinimum~,
        exclusiveMaximum~,
        multipleOf~,
      )
    }
    { "type": "integer", .. } => {
      let minimum = match obj.get("minimum") {
        Some(@json.Number(n, ..)) => n.to_int() |> Some
        _ => None
      }
      let maximum = match obj.get("maximum") {
        Some(@json.Number(n, ..)) => n.to_int() |> Some
        _ => None
      }
      let exclusiveMinimum = match obj.get("exclusiveMinimum") {
        Some(@json.Number(n, ..)) => n.to_int() |> Some
        _ => None
      }
      let exclusiveMaximum = match obj.get("exclusiveMaximum") {
        Some(@json.Number(n, ..)) => n.to_int() |> Some
        _ => None
      }
      let multipleOf = match obj.get("multipleOf") {
        Some(@json.Number(n, ..)) => n.to_int() |> Some
        _ => None
      }
      Schema::Integer(
        minimum~,
        maximum~,
        exclusiveMinimum~,
        exclusiveMaximum~,
        multipleOf~,
      )
    }
    { "type": "array", .. } => {
      let items = match obj.get("items") {
        Some(item_schema) =>
          Some(Schema::from_json(item_schema, json_path.add_key("items")))
        None => None
      }
      let minItems = match obj.get("minItems") {
        Some(@json.Number(n, ..)) => Some(n.to_int())
        _ => None
      }
      let maxItems = match obj.get("maxItems") {
        Some(@json.Number(n, ..)) => Some(n.to_int())
        _ => None
      }
      let uniqueItems = match obj.get("uniqueItems") {
        Some(@json.True) => Some(true)
        Some(@json.False) => Some(false)
        _ => None
      }
      Schema::Array(
        items~,
        minItems~,
        maxItems~,
        uniqueItems~,
        prefixItems=None,
        contains=None,
        minContains=None,
        maxContains=None,
      )
    }
    { "type": "object", .. } => {
      let properties = match obj.get("properties") {
        Some(@json.Object(props_obj)) => {
          let props_map : Map[String, Schema] = {}
          for k, v in props_obj {
            props_map.set(k, Schema::from_json(v, json_path.add_key(k)))
          }
          Some(props_map)
        }
        _ => None
      }
      let required = match obj.get("required") {
        Some(@json.Array(req_array)) => {
          let req_props : Array[String] = []
          for i = 0; i < req_array.length(); i = i + 1 {
            match req_array[i] {
              @json.String(prop) => req_props.push(prop)
              _ => ()
            }
          }
          Some(req_props)
        }
        _ => None
      }
      Schema::Object(
        properties~,
        required~,
        additionalProperties=None,
        patternProperties=None,
        propertyNames=None,
        dependentSchemas=None,
        dependentRequired=None,
        minProperties=None,
        maxProperties=None,
      )
    }
    { "anyOf": Array(schemas), .. } =>
      Schema::AnyOf(
        schemas.map(fn(s) {
          @json.from_json(s, path=json_path.add_key("anyOf"))
        }),
      )
    { "allOf": Array(schemas), .. } =>
      Schema::AllOf(
        schemas.map(fn(s) {
          @json.from_json(s, path=json_path.add_key("allOf"))
        }),
      )
    { "oneOf": Array(schemas), .. } =>
      Schema::OneOf(
        schemas.map(fn(s) {
          @json.from_json(s, path=json_path.add_key("oneOf"))
        }),
      )
    { "not": schema, .. } =>
      Schema::Not(@json.from_json(schema, path=json_path.add_key("not")))
    { "enum": Array(values), .. } => Schema::Enum(values)
    { "const": value, .. } => Schema::Const(value)
    _ => Schema::Any
  }
}

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
