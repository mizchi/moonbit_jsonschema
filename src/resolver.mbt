///|
pub struct Resolver {
  priv resolver_map : Map[String, JsonSchema]
}

///|
pub fn Resolver::new(root_json : Json) -> Resolver raise {
  let resolver_map : Map[String, JsonSchema] = {}
  let using_refs = collect_refs(root_json)
  for ref_expr in using_refs {
    guard JsonPointer::from_string(ref_expr) is Ok(pointer) else {
      fail("invalid $ref: " + ref_expr)
    }
    match pointer.access(root_json) {
      Some(json) =>
        try {
          let schema : JsonSchema = @json.from_json(json)
          resolver_map.set(ref_expr, schema)
        } catch {
          // TODO: log error
          _ => ()
        }
      None => ()
    }
  }
  Resolver::{ resolver_map, }
}

///|
pub fn resolve(self : Resolver, ref_expr : String) -> JsonSchema? {
  self.resolver_map.get(ref_expr)
}

///|
pub fn has(self : Resolver, ref_expr : String) -> Bool {
  self.resolver_map.contains(ref_expr)
}

///|
pub fn get_refs(self : Resolver) -> Array[String] {
  self.resolver_map.keys().to_array()
}

///|
pub fn build_resolver(root_json : Json) -> (JsonPointer) -> JsonSchema? {
  let resolver_map : Map[String, JsonSchema] = {}
  let using_refs = collect_refs(root_json)
  for ref_expr in using_refs {
    guard JsonPointer::from_string(ref_expr) is Ok(pointer) else {
      // TODO: warning
      return fn(_) { None }
    }
    match pointer.access(root_json) {
      Some(json) =>
        try {
          let schema : JsonSchema = @json.from_json(json)
          resolver_map.set(ref_expr, schema)
        } catch {
          // TODO: log error
          _ => ()
        }
      None => ()
    }
  }
  fn(ref_expr) { resolver_map.get(ref_expr.to_string()) }
}

///|
/// get $ref references in json
pub fn collect_refs(json : Json) -> Set[String] {
  let set : Set[String] = Set::new()
  match json {
    Object(obj) =>
      for key, value in obj {
        if key == "$ref" && value is String(s) {
          set.add(s)
        } else {
          let newset = collect_refs(value)
          for s in newset {
            set.add(s)
          }
        }
      }
    Array(arr) =>
      for item in arr {
        let newset = collect_refs(item)
        for s in newset {
          set.add(s)
        }
      }
    _ => ()
  }
  set
}

///|
test "collect_refs" {
  let json : Json = {
    "type": "object",
    "properties": {
      "name": { "type": "string" },
      "age": { "$ref": "#/definitions/PositiveInteger" },
      "friends": {
        "type": "array",
        "items": { "$ref": "#/definitions/Person" },
      },
    },
    "definitions": {
      "Person": {
        "type": "object",
        "properties": {
          "name": { "type": "string" },
          "age": { "$ref": "#/definitions/PositiveInteger" },
        },
      },
      "PositiveInteger": { "type": "integer", "minimum": 0 },
    },
  }
  let refs = collect_refs(json)
  assert_eq(
    refs,
    Set::from_array(["#/definitions/PositiveInteger", "#/definitions/Person"]),
  )
}
