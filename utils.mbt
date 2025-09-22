///|
/// get $ref references in json
fn traverse_refs_in_json(json : Json) -> Set[String] {
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
