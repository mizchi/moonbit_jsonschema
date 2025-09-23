///|
/// get $ref references in json
pub fn traverse_refs_in_json(json : Json) -> Set[String] {
  let set : Set[String] = Set::new()
  match json {
    Object(obj) =>
      for key, value in obj {
        if key == "$ref" && value is String(s) {
          set.add(s)
        } else {
          let newset = traverse_refs_in_json(value)
          for s in newset {
            set.add(s)
          }
        }
      }
    Array(arr) =>
      for item in arr {
        let newset = traverse_refs_in_json(item)
        for s in newset {
          set.add(s)
        }
      }
    _ => ()
  }
  set
}

///|
pub fn build_resolver(root_json : Json) -> (String) -> JsonSchema? {
  let resolver_map : Map[String, JsonSchema] = {}
  let using_refs = traverse_refs_in_json(root_json)
  for ref_expr in using_refs {
    guard JsonPointer::from_string(ref_expr) is Ok(pointer) else {
      // TODO: warning
      return fn(_s) { None }
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
  fn(ref_expr) { resolver_map.get(ref_expr) }
}

///|
test "traverse refs in json" {
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
  let refs = traverse_refs_in_json(json)
  assert_eq(
    refs,
    Set::from_array(["#/definitions/PositiveInteger", "#/definitions/Person"]),
  )
}
