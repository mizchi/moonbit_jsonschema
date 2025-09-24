///|
test "json literal" {
  let json : Json = {
    "a": 10,
    "b": "str",
    "c": [1, 2, 3],
    "nested": { "d": { "v": 1 } },
  }
  let _ : Json = "json string"
  json.stringify()
  |> assert_eq(
    "{\"a\":10,\"b\":\"str\",\"c\":[1,2,3],\"nested\":{\"d\":{\"v\":1}}}",
  )
  // match Json::Object(Map[String, Json])
  if json is Json::Object(obj) {
    let _ : Map[String, Json] = obj
    assert_eq(obj.get("a"), Some(10))
    assert_eq(obj.get("b"), Some("str"))
  } else {
    fail("unreachable")
  }
}

///|
test "parse json" {
  let s = "{\"a\":10,\"b\":\"str\",\"c\":[1,2,3],\"nested\":{\"d\":{\"v\":1}}}"
  let json : Json = @json.parse(s)
  inspect(
    json,
    content=(
      #|Object({"a": Number(10), "b": String("str"), "c": Array([Number(1), Number(2), Number(3)]), "nested": Object({"d": Object({"v": Number(1)})})})
    ),
  )
}

///|
struct TestItem {
  v : Int
} derive(FromJson, ToJson, Eq, Show)

///|
test "json pattern match" {
  let json : Json = {
    "a": 10,
    "b": "str",
    "c": [1, 2, 3],
    "nested": { "d": { "v": 1 } },
    "nested_array": [{ "v": 1 }, { "v": 2 }],
  }
  guard json is Json::Object(obj) else { fail("not object") }
  let _ : Map[String, Json] = obj

  // check key
  obj.contains("a") |> assert_true
  obj.contains("x") |> assert_false

  // Can omit Json::
  if obj is { "a": Json::Number(v, ..), .. } {
    assert_eq(v, 10.0)
  } else {
    fail("unreachable")
  }
  if obj is { "a": Json::Number(v, ..), .. } {
    assert_eq(v.to_int(), 10)
  } else {
    fail("unreachable")
  }
  // array pattern
  if obj is { "c": Array(array), .. } {
    let _ : Array[Json] = array
    assert_eq(array, [1, 2, 3])
  } else {
    fail("unreachable")
  }
  if obj is { "c": Array([1, .. rest]), .. } {
    assert_eq(rest, [2, 3])
  } else {
    fail("unreachable")
  }
  // access deeply nested value
  if obj is { "nested": { "d": { "v": Json::Number(v, ..), .. }, .. }, .. } {
    assert_eq(v.to_int(), 1)
  } else {
    fail("unreachable")
  }
  // with FromJson trait
  if obj is { "nested_array": Array(values), .. } {
    assert_eq(values, [{ "v": 1 }, { "v": 2 }])
  } else {
    fail("unreachable")
  }
}

///|
test "json array with FromJson/ToJson" {
  let json : Json = { "nested_array": [{ "v": 1 }, { "v": 2 }] }
  guard json is Json::Object(obj) else { fail("not object") }
  guard obj is { "nested_array": Array(values), .. } else {
    fail("unreachable")
  }
  // TestItem:: from_json trait
  let items : Array[TestItem] = values.map(value => @json.from_json(value))
  assert_eq(items, [{ v: 1 }, { v: 2 }])
  // TestItem:: to_json trait
  let json_str = items.to_json().stringify()
  assert_eq(json_str, "[{\"v\":1},{\"v\":2}]")
}

///|
/// rename field in json to avoid using reserved keywords
priv struct TestStructWithRename {
  type_renamed : Int
} derive (
  FromJson(fields(type_renamed(rename="type"))),
  ToJson(fields(type_renamed(rename="type"))),
  Show,
  Eq,
)

///|
/// same but manually implement FromJson, ToJson
priv struct TestStructWithRenameManually {
  type_renamed : Int
} derive(Show, Eq)

///|
impl @json.FromJson for TestStructWithRenameManually with from_json(
  json : Json,
  path : @json.JsonPath,
) -> TestStructWithRenameManually raise @json.JsonDecodeError {
  if json is Json::Object(obj) {
    guard obj.get("type") is Some(Json::Number(v, ..)) else {
      raise @json.JsonDecodeError(
        (path.add_key("type"), "type field missing or not a number"),
      )
    }
    TestStructWithRenameManually::{ type_renamed: v.to_int() }
  } else {
    raise @json.JsonDecodeError(
      (path.add_key("type"), "type field missing or not a number"),
    )
  }
}

///|
impl ToJson for TestStructWithRenameManually with to_json(self) -> Json {
  { "type": self.type_renamed.to_json() }
}

///|
test "json with rename" {
  let s : String = "{\"type\":10}"

  // for TestStructWithRename
  let json : Json = @json.parse(s)
  let obj : TestStructWithRename = @json.from_json(json)
  assert_eq(obj, TestStructWithRename::{ type_renamed: 10 })
  let json2 : Json = obj.to_json()
  assert_eq(json2.stringify(), s)

  // for TestStructWithRenameManually
  let obj2 : TestStructWithRenameManually = @json.from_json(json)
  assert_eq(obj2, TestStructWithRenameManually::{ type_renamed: 10 })
  let json3 : Json = obj2.to_json()
  assert_eq(json3.stringify(), s)
}
