// JSON Schema types and definitions

///|
pub struct ObjectConstraints {
  properties : Map[String, JsonSchema]?
  required : Array[String]?
  additional_properties : JsonSchema?
  // pattern_properties : Map[String, JsonSchema]?
  // property_names : JsonSchema?
  // dependent_schemas : Map[String, JsonSchema]?
  // dependent_required : Map[String, Array[String]]?
  // min_properties : Int?
  // max_properties : Int?
  // description : String?
} derive (
  Show,
  Eq,
  FromJson(
    fields(
      additional_properties(rename="additionalProperties"),
      pattern_properties(rename="patternProperties"),
      property_names(rename="propertyNames"),
      // dependent_schemas(rename="dependentSchemas"),
      // dependent_required(rename="dependentRequired"),
      // min_properties(rename="minProperties"),
      // max_properties(rename="maxProperties"),
    ),
  ),
  ToJson(
    fields(
      additional_properties(rename="additionalProperties"),
      pattern_properties(rename="patternProperties"),
      // property_names(rename="propertyNames"),
      // dependent_schemas(rename="dependentSchemas"),
      // dependent_required(rename="dependentRequired"),
      // min_properties(rename="minProperties"),
      // max_properties(rename="maxProperties"),
    ),
  ),
)

///|
pub struct StringConstraint {
  minLength : Int?
  maxLength : Int?
  enum_ : Array[String]?
  // pattern : String?
  // format : String?
  // contentEncoding : String?
  // contentMediaType : String?
  // description : String?
} derive (
  Show,
  Eq,
  FromJson(fields(enum_(rename="enum"))),
  ToJson(fields(enum_(rename="enum"))),
)

///|
pub struct NumberConstraint {
  minimum : Double?
  maximum : Double?
  exclusive_minimum : Double?
  exclusive_maximum : Double?
  // multipleOf : Double?
} derive (
  Show,
  Eq,
  // FromJson(fields(exclusiveMinimum(rename="exclusiveMinimum"), exclusiveMaximum(rename="exclusiveMaximum"), multipleOf(rename="multipleOf"))),
  ToJson(
    fields(
      exclusiveMinimum(rename="exclusiveMinimum"),
      exclusiveMaximum(rename="exclusiveMaximum"),
      multiple_of(rename="multipleOf"),
    ),
  ),
  FromJson(
    fields(
      exclusiveMinimum(rename="exclusiveMinimum"),
      exclusiveMaximum(rename="exclusiveMaximum"),
      multiple_of(rename="multipleOf"),
    ),
  ),
)

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
fn with_type_property(json : Json, type_name : String) -> Json {
  guard json is Json::Object(obj) else { return json }
  let json : Map[String, Json] = { "type": type_name.to_json() }
  for k, v in obj {
    json[k] = v
  }
  return json.to_json()
}

///|
pub impl ToJson for JsonSchema with to_json(self) -> Json {
  let v : Json = match self {
    JsonSchema::Any(_) => { "type": "any" }
    JsonSchema::Null(_) => { "type": "null" }
    JsonSchema::Boolean(_) => { "type": "boolean" }
    JsonSchema::String(c) => with_type_property(c.to_json(), "string")
    Ref(pointer) => { "$ref": pointer.to_string() }
    Const(value) => { "const": value }
    Enum(values) => { "enum": values.to_json() }
    Number(c) => with_type_property(c.to_json(), "number")
    Integer(c) => with_type_property(c.to_json(), "integer")
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
    // let json : Map[String, Json] = { "type": "object" }
    Object(c) => with_type_property(c.to_json(), "object")
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
    { "type": "object", .. } =>
      ObjectConstraints::from_json(json, json_path) |> JsonSchema::Object
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
    { "type": "boolean", .. } => JsonSchema::Boolean(description~)
    { "type": "string", .. } =>
      StringConstraint::from_json(json, json_path) |> JsonSchema::String
    { "type": "number", .. } =>
      NumberConstraint::from_json(json, json_path) |> JsonSchema::Number
    { "type": "integer", .. } =>
      NumberConstraint::from_json(json, json_path) |> JsonSchema::Integer
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
