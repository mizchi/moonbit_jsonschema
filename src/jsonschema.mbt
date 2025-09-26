// JSON Schema types and definitions

///|
pub struct ObjectConstraints {
  properties : Map[String, JsonSchema]?
  required : Array[String]?
  additionalProperties : JsonSchema?
  patternProperties : Map[String, JsonSchema]?
  propertyNames : JsonSchema?
  dependentSchemas : Map[String, JsonSchema]?
  dependentRequired : Map[String, Array[String]]?
  minProperties : Int?
  maxProperties : Int?
  description : String?
} derive(Show, Eq)

///|
pub struct StringConstraint {
  minLength : Int?
  maxLength : Int?
  pattern : String?
  format : String?
  enum_ : Array[String]?
  contentEncoding : String?
  contentMediaType : String?
  // description : String?
} derive(Show, Eq)

///|
pub struct NumberConstraint {
  minimum : Double?
  maximum : Double?
  exclusiveMinimum : Double?
  exclusiveMaximum : Double?
  multipleOf : Double?
} derive(Show, Eq)

///|
/// JsonSchema
pub enum JsonSchema {
  /// { "type": "any" }
  Any(description~ : String?)
  /// { "type": "null" }
  Null(description~ : String?)
  /// { "type": "boolean" }
  Boolean(description~ : String?)
  /// { "type": "string" }
  String(StringConstraint)
  /// { "type": "number" }
  Number(NumberConstraint)
  //   minimum~ : Double?,
  //   maximum~ : Double?,
  //   exclusiveMinimum~ : Double?,
  //   exclusiveMaximum~ : Double?,
  //   multipleOf~ : Double?,
  // )
  /// { "type": "integer" }
  Integer(NumberConstraint)
  /// { "type": "array" }
  Array(
    items~ : JsonSchema?,
    prefixItems~ : Array[JsonSchema]?,
    contains~ : JsonSchema?,
    minContains~ : Int?,
    maxContains~ : Int?,
    minItems~ : Int?,
    maxItems~ : Int?,
    uniqueItems~ : Bool?,
    description~ : String?
  )
  /// { "type": "object" }
  Object(ObjectConstraints)
  /// { "enum": [...] }
  Enum(Array[Json])
  /// { "const": ... }
  Const(Json)
  /// { "anyOf": [...] }
  AnyOf(Array[JsonSchema])
  /// { "allOf": [...] }
  AllOf(Array[JsonSchema])
  /// { "oneOf": [...] }
  OneOf(Array[JsonSchema])
  /// { "not": ... }
  Not(JsonSchema)
  /// { "$ref": "..." }
  Ref(JsonPointer)
  // If(Schema, Schema?, Schema?) // if, then, else
} derive(Show, Eq)

///|
pub impl ToJson for JsonSchema with to_json(self) -> Json {
  let v : Json = match self {
    JsonSchema::Any(_) => { "type": "any" }.to_json()
    JsonSchema::Null(_) => { "type": "null" }.to_json()
    JsonSchema::Boolean(_) => { "type": "boolean" }.to_json()
    // description,
    JsonSchema::String(
      {
        minLength,
        maxLength,
        pattern,
        format,
        contentEncoding,
        contentMediaType,
        enum_,
      }
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
    Ref(pointer) => { "$ref": pointer.to_string() }.to_json()
    Const(value) => { "const": value }.to_json()
    // after string
    Enum(values) => { "enum": values.to_json() }.to_json()
    // description~
    Number({ minimum, maximum, exclusiveMinimum, exclusiveMaximum, multipleOf }) => {
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
    Integer(
      { minimum, maximum, exclusiveMinimum, exclusiveMaximum, multipleOf }
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
    Array(
      items~,
      prefixItems~,
      contains~,
      minContains~,
      maxContains~,
      minItems~,
      maxItems~,
      uniqueItems~,
      description~
    ) => {
      let json : Map[String, Json] = { "type": "array" }
      if items is Some(value) {
        json["items"] = value.to_json()
      }
      if prefixItems is Some(values) {
        json["prefixItems"] = values.map(fn(s) { s.to_json() }).to_json()
      }
      if contains is Some(value) {
        json["contains"] = value.to_json()
      }
      if minContains is Some(value) {
        json["minContains"] = value.to_json()
      }
      if maxContains is Some(value) {
        json["maxContains"] = value.to_json()
      }
      if minItems is Some(value) {
        json["minItems"] = value.to_json()
      }
      if maxItems is Some(value) {
        json["maxItems"] = value.to_json()
      }
      if uniqueItems is Some(value) {
        json["uniqueItems"] = value.to_json()
      }
      if description is Some(value) {
        json["description"] = value.to_json()
      }
      json.to_json()
    }
    Object(
      {
        properties,
        required,
        additionalProperties,
        patternProperties,
        propertyNames,
        dependentSchemas,
        dependentRequired,
        minProperties,
        maxProperties,
        description,
      }
    ) => {
      let json : Map[String, Json] = { "type": "object" }
      if properties is Some(props) {
        let props_json : Map[String, Json] = {}
        for k, v in props {
          props_json[k] = v.to_json()
        }
        json["properties"] = props_json.to_json()
      }
      if required is Some(req) {
        json["required"] = req.to_json()
      }
      if additionalProperties is Some(value) {
        json["additionalProperties"] = value.to_json()
      }
      if patternProperties is Some(pat_props) {
        let pat_props_json : Map[String, Json] = {}
        for k, v in pat_props {
          pat_props_json[k] = v.to_json()
        }
        json["patternProperties"] = pat_props_json.to_json()
      }
      if propertyNames is Some(value) {
        json["propertyNames"] = value.to_json()
      }
      if dependentSchemas is Some(dep_schemas) {
        let dep_schemas_json : Map[String, Json] = {}
        for k, v in dep_schemas {
          dep_schemas_json[k] = v.to_json()
        }
        json["dependentSchemas"] = dep_schemas_json.to_json()
      }
      if dependentRequired is Some(dep_req) {
        let dep_req_json : Map[String, Json] = {}
        for k, v in dep_req {
          dep_req_json[k] = v.to_json()
        }
        json["dependentRequired"] = dep_req_json.to_json()
      }
      if minProperties is Some(value) {
        json["minProperties"] = value.to_json()
      }
      if maxProperties is Some(value) {
        json["maxProperties"] = value.to_json()
      }
      if description is Some(value) {
        json["description"] = value.to_json()
      }
      json.to_json()
    }
    JsonSchema::AnyOf(schemas) =>
      { "anyOf": schemas.map(fn(s) { s.to_json() }) }
    JsonSchema::AllOf(schemas) =>
      { "allOf": schemas.map(fn(s) { s.to_json() }) }
    JsonSchema::OneOf(schemas) =>
      { "oneOf": schemas.map(fn(s) { s.to_json() }) }
    JsonSchema::Not(schema) => { "not": schema }
  }
  v
}

///|
pub impl @json.FromJson for JsonSchema with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> JsonSchema raise {
  guard json is Json::Object(obj) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let description = match obj.get("description") {
    Some(String(desc)) => Some(desc)
    _ => None
  }
  let b = Builder::new()
  match obj {
    { "const": value, .. } => Const(value)
    { "$ref": @json.String(ref_expr), .. } =>
      // TODO: validate ref_expr
      JsonPointer::from_string(ref_expr).unwrap() |> Ref
    // TODO: redundant patterns
    { "type": @json.Array(["null", String(item_type)]), .. } => {
      let schema = match item_type {
        "string" => b.string()
        "number" => b.number()
        "integer" => b.integer()
        "boolean" => b.boolean()
        // TODO: raise error if unsupported type
        _ => b.any()
      }
      b.anyOf([schema, JsonSchema::Null(description=None)])
    }
    { "type": @json.Array([String(item_type), "null"]), .. } => {
      let schema = match item_type {
        "string" => b.string()
        "number" => b.number()
        "integer" => b.integer()
        "boolean" => b.boolean()
        // TODO: raise error if unsupported type
        _ => b.any()
      }
      b.anyOf([schema, b.null()])
    }
    { "type": "object", .. } => {
      let properties = match obj.get("properties") {
        Some(Object(props_obj)) => {
          let props_map : Map[String, JsonSchema] = {}
          for k, v in props_obj {
            props_map.set(k, JsonSchema::from_json(v, json_path.add_key(k)))
          }
          Some(props_map)
        }
        _ => None
      }
      let required : Array[String]? = match obj.get("required") {
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
      let additionalProperties = match obj.get("additionalProperties") {
        Some(Json::True) => Some(JsonSchema::Any(description=None))
        Some(Json::False) => None
        Some(json) =>
          JsonSchema::from_json(json, json_path.add_key("additionalProperties"))
          |> Some
        None => None
      }
      ObjectConstraints::{
        properties,
        required,
        additionalProperties,
        patternProperties: match obj.get("patternProperties") {
          Some(Object(pat_props_obj)) => {
            let pat_props_map : Map[String, JsonSchema] = {}
            for k, v in pat_props_obj {
              pat_props_map.set(
                k,
                JsonSchema::from_json(v, json_path.add_key(k)),
              )
            }
            Some(pat_props_map)
          }
          _ => None
        },
        propertyNames: match obj.get("propertyNames") {
          Some(json) =>
            JsonSchema::from_json(json, json_path.add_key("propertyNames"))
            |> Some
          None => None
        },
        dependentSchemas: match obj.get("dependentSchemas") {
          Some(Object(dep_schemas_obj)) => {
            let dep_schemas_map : Map[String, JsonSchema] = {}
            for k, v in dep_schemas_obj {
              dep_schemas_map.set(
                k,
                JsonSchema::from_json(v, json_path.add_key(k)),
              )
            }
            Some(dep_schemas_map)
          }
          _ => None
        },
        dependentRequired: match obj.get("dependentRequired") {
          Some(Object(dep_req_obj)) => {
            let dep_req_map : Map[String, Array[String]] = {}
            for k, v in dep_req_obj {
              match v {
                @json.Array(arr) => {
                  let req_props : Array[String] = []
                  for i = 0; i < arr.length(); i = i + 1 {
                    match arr[i] {
                      @json.String(prop) => req_props.push(prop)
                      _ => ()
                    }
                  }
                  dep_req_map.set(k, req_props)
                }
                _ => ()
              }
            }
            Some(dep_req_map)
          }
          _ => None
        },
        minProperties: match obj.get("minProperties") {
          Some(@json.Number(n, ..)) => Some(n.to_int())
          _ => None
        },
        maxProperties: match obj.get("maxProperties") {
          Some(@json.Number(n, ..)) => Some(n.to_int())
          _ => None
        },
        description,
      }
      |> JsonSchema::Object
    }
    { "type": "array", .. } => {
      let items = match obj.get("items") {
        Some(item_schema) =>
          Some(JsonSchema::from_json(item_schema, json_path.add_key("items")))
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
      let prefixItems = match obj.get("prefixItems") {
        Some(@json.Array(arr)) =>
          Some(
            arr.mapi(fn(i, s) {
              JsonSchema::from_json(
                s,
                json_path.add_key("prefixItems").add_index(i),
              )
            }),
          )
        _ => None
      }
      Array(
        items~,
        minItems~,
        maxItems~,
        uniqueItems~,
        description~,
        prefixItems~,
        contains=None,
        minContains=None,
        maxContains=None,
      )
    }
    { "type": "null", .. } => JsonSchema::Null(description~)
    { "type": "boolean", .. } => {
      let description = match obj.get("description") {
        Some(@json.String(desc)) => Some(desc)
        _ => None
      }
      JsonSchema::Boolean(description~)
    }
    { "type": "string", .. } => {
      // let description = match obj.get("description") {
      //   Some(@json.String(desc)) => Some(desc)
      //   _ => None
      // }
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
      JsonSchema::String(StringConstraint::{
        minLength,
        maxLength,
        pattern,
        enum_,
        format,
        contentEncoding: None,
        contentMediaType: None,
        // description~,
      })
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
      JsonSchema::Number({
        minimum,
        maximum,
        exclusiveMinimum,
        exclusiveMaximum,
        multipleOf,
      })
    }
    { "type": "integer", .. } => {
      let minimum = match obj.get("minimum") {
        Some(@json.Number(n, ..)) => n |> Some
        _ => None
      }
      let maximum = match obj.get("maximum") {
        Some(@json.Number(n, ..)) => n |> Some
        _ => None
      }
      let exclusiveMinimum = match obj.get("exclusiveMinimum") {
        Some(@json.Number(n, ..)) => n |> Some
        _ => None
      }
      let exclusiveMaximum = match obj.get("exclusiveMaximum") {
        Some(@json.Number(n, ..)) => n |> Some
        _ => None
      }
      let multipleOf = match obj.get("multipleOf") {
        Some(@json.Number(n, ..)) => n |> Some
        _ => None
      }
      JsonSchema::Integer({
        minimum,
        maximum,
        exclusiveMinimum,
        exclusiveMaximum,
        multipleOf,
      })
    }
    { "anyOf": Array(schemas), .. } =>
      JsonSchema::AnyOf(
        schemas.map(fn(s) {
          @json.from_json(s, path=json_path.add_key("anyOf"))
        }),
      )
    { "allOf": Array(schemas), .. } =>
      JsonSchema::AllOf(
        schemas.map(fn(s) {
          @json.from_json(s, path=json_path.add_key("allOf"))
        }),
      )
    { "oneOf": Array(schemas), .. } =>
      JsonSchema::OneOf(
        schemas.mapi(fn(i, s) {
          @json.from_json(s, path=json_path.add_key("oneOf").add_index(i))
        }),
      )
    { "not": schema, .. } =>
      JsonSchema::Not(@json.from_json(schema, path=json_path.add_key("not")))
    { "enum": Array(values), .. } => JsonSchema::Enum(values)
    _ => JsonSchema::Any(description~)
  }
}
