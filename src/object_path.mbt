///|
enum ObjectPath {
  Root
  Key(ObjectPath, key~ : String)
  Index(ObjectPath, index~ : Int)
} derive(Eq)

///|
fn add_index(self : ObjectPath, index : Int) -> ObjectPath {
  Index(self, index~)
}

///|
fn add_key(self : ObjectPath, key : String) -> ObjectPath {
  Key(self, key~)
}

///|
pub impl Show for ObjectPath with output(self, logger) {
  match self {
    Root => logger.write_string("#")
    Key(p, key~) =>
      logger..write_object(p)..write_string("/")..write_string(key)
    Index(p, index~) =>
      logger..write_object(p)..write_string("/")..write_object(index)
  }
}

///|
fn ObjectPath::access(self : ObjectPath, json : Json) -> Json? {
  match self {
    Root => Some(json)
    Key(parent, key~) =>
      match parent.access(json) {
        Some(Object(obj)) => obj.get(key)
        _ => None
      }
    Index(parent, index~) =>
      match parent.access(json) {
        Some(Array(arr)) =>
          if index >= 0 && index < arr.length() {
            Some(arr[index])
          } else {
            None
          }
        _ => None
      }
  }
}

///|
suberror JsonPointerDecodeError String

///|
fn ObjectPath::from_json_pointer(
  pointer : String,
) -> ObjectPath raise JsonPointerDecodeError {
  if pointer == "#" || pointer == "" {
    return Root
  }
  let normalized = try {
    // Remove leading # or #/ if present
    if pointer.has_prefix("#/") {
      pointer[2:]
    } else if pointer.has_prefix("#") {
      pointer[1:]
    } else if pointer.has_prefix("/") {
      pointer[1:]
    } else {
      pointer
    }
  } catch {
    _ => raise JsonPointerDecodeError("Invalid JSON Pointer: \{pointer}")
  }

  // Split by / and build path
  let parts = normalized.split("/")
  let mut path = Root
  for part in parts {
    if part == "" {
      continue
    }
    let part_str = part.to_string()

    // Check if this is a number (array index)
    let is_digit = fn(c : Char) -> Bool { c >= '0' && c <= '9' }
    let is_number = part_str.length() > 0 && part_str.iter().all(is_digit)
    if is_number {
      let mut num = 0
      for ch in part_str.iter() {
        num = num * 10 + (ch.to_int() - '0'.to_int())
      }
      path = path.add_index(num)
    } else {
      let unescaped = part_str
        .replace(old="~1", new="/")
        .replace(old="~0", new="~")
      path = path.add_key(unescaped)
    }
  }
  path
}

///|
test "ObjectPath" {
  let path = Root.add_key("foo").add_index(0).add_key("bar")
  assert_eq(path.to_string(), "#/foo/0/bar")
  let object_path = Root.add_key("foo").add_index(0).add_key("bar")
  let json : Json = { "foo": [{ "bar": 42 }] }
  let resolved = object_path.access(json).unwrap()
  assert_eq(resolved, 42)
}

///|
test "ObjectPath::from_pointer" {
  let path1 = ObjectPath::from_json_pointer("#/foo/0/bar")
  let expected1 = Root.add_key("foo").add_index(0).add_key("bar")
  assert_eq(path1, expected1)
  let path2 = ObjectPath::from_json_pointer("/foo/bar")
  let expected2 = Root.add_key("foo").add_key("bar")
  assert_eq(path2, expected2)
  let path3 = ObjectPath::from_json_pointer("#")
  assert_eq(path3, Root)
  let path4 = ObjectPath::from_json_pointer("")
  assert_eq(path4, Root)
  let path5 = ObjectPath::from_json_pointer("#/foo~1bar/0")
  let expected5 = Root.add_key("foo/bar").add_index(0)
  assert_eq(path5, expected5)
  let path6 = ObjectPath::from_json_pointer("#/foo~0bar")
  let expected6 = Root.add_key("foo~bar")
  assert_eq(path6, expected6)
}

///|
test "ObjectPath::from_json_pointer" {
  let result = ObjectPath::from_json_pointer("#/abc/items/0/def") catch {
    err => raise err
  }
  result |> inspect(content="#/abc/items/0/def")
  // assert(result is Err(JsonPointerDecodeError(_)))
}
