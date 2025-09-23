// JSON Schema Validator tests

///|
fn[T, E] assert_ok(x : Result[T, E]) -> Unit {
  guard x is Ok(_)
}

///|
fn[T, E] assert_err(x : Result[T, E]) -> Unit {
  guard x is Err(_)
}

///|
test "validate null" {
  let schema = JsonSchema::null()
  schema.validate(null) |> assert_ok
  schema.validate("not-null") |> assert_err
  schema.validate(1)
  |> inspect(
    content=(
      #|Err([{input: Number(1), json_path: #, schema_path: #, message: "Value is not null", children: None}])
    ),
  )
}

///|
test "validate const" {
  let schema = JsonSchema::const_(Json::string("constant"))
  schema.validate("constant") |> assert_ok
  schema.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Number(1), json_path: #, schema_path: #, message: "Value does not match constant value String(\"constant\")", children: None}]
    ),
  )
}

///|
test "validate const nested" {
  let schema = JsonSchema::const_({ "nested": true })
  schema.validate({ "nested": true }) |> assert_ok
  schema.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Number(1), json_path: #, schema_path: #, message: "Value does not match constant value Object({\"nested\": True})", children: None}]
    ),
  )
}

///|
test "validate any" {
  let schema = JsonSchema::any()
  schema.validate(null) |> assert_ok
  schema.validate({}) |> assert_ok
}

///|
test "validate string" {
  let schema = JsonSchema::string()
  schema.validate("hello") |> assert_ok
  schema.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Number(1), json_path: #, schema_path: #, message: "Value is not a string", children: None}]
    ),
  )
}

///|
test "validate string with enum" {
  let schema = JsonSchema::string(enum_=["a", "b"])
  schema.validate("a") |> assert_ok
  schema.validate("b") |> assert_ok
  schema.validate("c").unwrap_err()
  |> inspect(
    content=(
      #|[{input: String("c"), json_path: #, schema_path: #/enum, message: "c is not in [\"a\", \"b\"]", children: None}]
    ),
  )
}

///|
test "validate string type with minLength and maxLength" {
  let schema = JsonSchema::string(minLength=3, maxLength=5)
  schema.validate("hey") |> assert_ok
  schema.validate("hi").unwrap_err()
  |> inspect(
    content=(
      #|[{input: String("hi"), json_path: #, schema_path: #/minLength, message: "String length 2 is less than minimum 3", children: None}]
    ),
  )
  schema.validate("hellooo")
  |> inspect(
    content=(
      #|Err([{input: String("hellooo"), json_path: #, schema_path: #/maxLength, message: "String length 7 is greater than maximum 5", children: None}])
    ),
  )
}

///|
test "validate enum" {
  let schema = JsonSchema::enum_(["red", "green", "blue"])
  schema.validate("red") |> assert_ok
  schema.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Number(1), json_path: #, schema_path: #, message: "Number(1) is not in [String(\"red\"), String(\"green\"), String(\"blue\")]", children: None}]
    ),
  )
  schema.validate("yellow").unwrap_err()
  |> inspect(
    content=(
      #|[{input: String("yellow"), json_path: #, schema_path: #, message: "String(\"yellow\") is not in [String(\"red\"), String(\"green\"), String(\"blue\")]", children: None}]
    ),
  )
}

///|
test "validate number" {
  let schema = JsonSchema::number(minimum=0.0, maximum=100.0)
  schema.validate(0) |> assert_ok
  schema.validate(1.1) |> assert_ok
}

///|
test "validate number with constraints" {
  let schema = JsonSchema::number(minimum=0.0, maximum=100.0)
  schema.validate(0) |> assert_ok
  schema.validate(1) |> assert_ok
  schema.validate(100) |> assert_ok
  schema.validate(-10)
  |> inspect(
    content=(
      #|Err([{input: Number(-10), json_path: #, schema_path: #/minimum, message: "Value is less than minimum 0", children: None}])
    ),
  )
  schema.validate("invalid")
  |> inspect(
    content=(
      #|Err([{input: String("invalid"), json_path: #, schema_path: #, message: "Value is not a number", children: None}])
    ),
  )
}

///|
test "validate number with exclusiveMinimum and exclusiveMaximum" {
  let schema = JsonSchema::number(exclusiveMinimum=0.0, exclusiveMaximum=10.0)
  schema.validate(0.0) |> assert_err
  schema.validate(1) |> assert_ok
  schema.validate(10.0) |> assert_err
}

///|
test "validate integer" {
  let schema = JsonSchema::integer()
  schema.validate(0) |> assert_ok
  schema.validate(1.1).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Number(1.1), json_path: #, schema_path: #, message: "Value is not an integer", children: None}]
    ),
  )
  schema.validate(1.0) |> assert_ok
}

///|
test "validate integer with constraints" {
  let schema = JsonSchema::integer(minimum=0, maximum=10)
  schema.validate(0) |> assert_ok
  schema.validate(1) |> assert_ok
  schema.validate(10) |> assert_ok
  schema.validate(-10)
  |> inspect(
    content=(
      #|Err([{input: Number(-10), json_path: #, schema_path: #/minimum, message: "Value is less than minimum 0", children: None}])
    ),
  )
  schema.validate("invalid")
  |> inspect(
    content=(
      #|Err([{input: String("invalid"), json_path: #, schema_path: #, message: "Value is not a number", children: None}])
    ),
  )
}

///|
test "validate integer with exclusiveMinimum and exclusiveMaximum" {
  let schema = JsonSchema::integer(exclusiveMinimum=0, exclusiveMaximum=10)
  schema.validate(0) |> assert_err
  schema.validate(1) |> assert_ok
  schema.validate(10) |> assert_err
}

///|
test "validate object" {
  let schema = JsonSchema::object(properties={ "name": JsonSchema::string() }, required=[
    "name",
  ])
  // println(schema)
  schema.validate({ "name": "John" }) |> assert_ok
  schema.validate({ "name": 0 }).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Number(0), json_path: #/name, schema_path: #/properties/name, message: "Value is not a string", children: None}]
    ),
  )
  // no required
  schema.validate({}).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Object({}), json_path: #/name, schema_path: #/required, message: "Required property 'name' is missing", children: None}]
    ),
  )
  let schema_no_required = JsonSchema::object(properties={
    "name": JsonSchema::string(),
  })
  schema_no_required.validate({}) |> assert_ok
  schema_no_required.validate({ "name": "foo" }).unwrap()
  |> inspect(content="()")
  schema_no_required.validate({ "name": 1 }).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Number(1), json_path: #/name, schema_path: #/properties/name, message: "Value is not a string", children: None}]
    ),
  )
}

///|
test "validate object with additionalProperties" {
  let schema = JsonSchema::object(properties={ "name": JsonSchema::string() }, required=[
    "name",
  ])
  schema.validate({ "name": "John" }) |> assert_ok()
  schema.validate({ "name": "John", "notAllowd": true })
  |> inspect(
    content=(
      #|Err([{input: Object({"name": String("John"), "notAllowd": True}), json_path: #/notAllowd, schema_path: #/additionalProperties, message: "Additional property '{\"notAllowd\"}' is not allowed", children: None}])
    ),
  )
  let schema2 = JsonSchema::object(
    properties={ "name": JsonSchema::string() },
    required=["name"],
    additionalProperties=JsonSchema::string(),
  )
  schema2.validate({ "name": "John" }) |> assert_ok
  schema2.validate({ "name": "John", "ex1": "x" }).unwrap()
  |> inspect(content="()")
  schema2.validate({ "name": "John", "ex1": 1 }).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Number(1), json_path: #/ex1, schema_path: #/additionalProperties, message: "Value is not a string", children: None}]
    ),
  )
}

///|
test "validate array" {
  let schema = JsonSchema::array(
    items=JsonSchema::object(properties={ "id": JsonSchema::integer() }, required=[
      "id",
    ]),
  )
  schema.validate([]) |> assert_ok
  schema.validate([{ "id": 1 }]) |> assert_ok
  schema.validate([{ "id": 1 }, { "id": "not-allowed" }]).unwrap_err()
  |> inspect(
    content=(
      #|[{input: String("not-allowed"), json_path: #/1/id, schema_path: #/items/properties/id, message: "Value is not a number", children: None}]
    ),
  )
}

///|
test "validate array with constraints" {
  let schema = JsonSchema::array(
    items=JsonSchema::integer(),
    minItems=1,
    maxItems=3,
  )
  schema.validate([]).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Array([]), json_path: #, schema_path: #/minItems, message: "Array length 0 is less than minimum 1", children: None}]
    ),
  )
  schema.validate([1]) |> assert_ok
  schema.validate([1, 2, 3, 4]).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Array([Number(1), Number(2), Number(3), Number(4)]), json_path: #, schema_path: #/maxItems, message: "Array length 4 is greater than maximum 3", children: None}]
    ),
  )
}

///|
test "validate array with prefixItems" {
  let schema = JsonSchema::array(prefixItems=[
    JsonSchema::const_("t"),
    JsonSchema::integer(),
  ])
  schema.validate([]) |> assert_err
  schema.validate(["t", 1]) |> assert_ok
  schema.validate(["t", "v"]) |> assert_err
  schema.validate(["x", 1, 2]) |> assert_err
}

///|
test "validate oneOf" {
  let schema = JsonSchema::oneOf([JsonSchema::string()])
  schema.validate("hello") |> assert_ok
  let schema = JsonSchema::oneOf([JsonSchema::string(), JsonSchema::null()])
  schema.validate("hello") |> assert_ok
  schema.validate(null) |> assert_ok
  schema.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Number(1), json_path: #, schema_path: #/oneOf/0, message: "Value is not a string", children: None}, {input: Number(1), json_path: #, schema_path: #/oneOf/1, message: "Value is not null", children: None}, {input: Number(1), json_path: #, schema_path: #/oneOf, message: "Value does not match exactly one schema in oneOf", children: None}]
    ),
  )
}

///|
test "validate allOf" {
  let schema = JsonSchema::allOf([JsonSchema::string()])
  schema.validate("hello") |> assert_ok
  let schema2 = JsonSchema::allOf([
    JsonSchema::string(),
    JsonSchema::const_("foo"),
  ])
  schema2.validate("foo") |> assert_ok
  schema2.validate("bar").unwrap_err()
  |> inspect(
    content=(
      #|[{input: String("bar"), json_path: #, schema_path: #/oneOf/1, message: "Value does not match constant value String(\"foo\")", children: None}, {input: String("bar"), json_path: #, schema_path: #/allOf, message: "Value does not match exactly one schema in allOf", children: None}]
    ),
  )
}

///|
test "validate anyOf" {
  let schema = JsonSchema::anyOf([JsonSchema::string()])
  schema.validate("hello") |> assert_ok
  let schema2 = JsonSchema::anyOf([
    JsonSchema::string(),
    JsonSchema::const_("foo"),
  ])
  schema2.validate("foo") |> assert_ok
  schema2.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Number(1), json_path: #, schema_path: #/anyOf/0, message: "Value is not a string", children: None}, {input: Number(1), json_path: #, schema_path: #/anyOf/1, message: "Value does not match constant value String(\"foo\")", children: None}, {input: Number(1), json_path: #, schema_path: #/anyOf, message: "Value does not match any schema in anyOf", children: None}]
    ),
  )
  let schema3 = JsonSchema::anyOf([
    JsonSchema::string(),
    JsonSchema::const_("foo"),
    JsonSchema::null(),
  ])
  schema3.validate(null) |> assert_ok
  schema3.validate("foo") |> assert_ok
  schema3.validate("bar") |> assert_ok
  schema3.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{input: Number(1), json_path: #, schema_path: #/anyOf/0, message: "Value is not a string", children: None}, {input: Number(1), json_path: #, schema_path: #/anyOf/1, message: "Value does not match constant value String(\"foo\")", children: None}, {input: Number(1), json_path: #, schema_path: #/anyOf/2, message: "Value is not null", children: None}, {input: Number(1), json_path: #, schema_path: #/anyOf, message: "Value does not match any schema in anyOf", children: None}]
    ),
  )
}

///|
test "validate $ref" {
  let raw_schema : Json = {
    "definitions": { "PositiveInteger": { "type": "integer", "minimum": 0 } },
    "$ref": "#/definitions/PositiveInteger",
  }
  let validator = build_validator(raw_schema)
  validator.validate(5) |> assert_ok
  validator.validate("err").unwrap_err()
  |> inspect(
    content=(
      #|[{input: String("err"), json_path: #, schema_path: #/$ref, message: "Value is not a number", children: None}]
    ),
  )
}

///|
test "validate $ref in array" {
  let raw_schema : Json = {
    "definitions": {
      "Point": {
        "type": "object",
        "required": ["x", "y"],
        "properties": { "x": { "type": "integer" }, "y": { "type": "integer" } },
      },
    },
    "type": "array",
    "items": { "$ref": "#/definitions/Point" },
  }
  let validator = build_validator(raw_schema)
  validator.validate([{ "x": 1, "y": 2 }]) |> assert_ok
  validator.validate([{ "x": "err", "y": 2 }]).unwrap_err()
  |> inspect(
    content=(
      #|[{input: String("err"), json_path: #/0/x, schema_path: #/items/$ref/properties/x, message: "Value is not a number", children: None}]
    ),
  )
}

///|
test "validate $ref in object" {
  let raw_schema : Json = {
    "definitions": {
      "Point": {
        "type": "object",
        "required": ["x", "y"],
        "properties": { "x": { "type": "integer" }, "y": { "type": "integer" } },
      },
    },
    "type": "object",
    "required": ["p1", "p2"],
    "properties": {
      "p1": { "$ref": "#/definitions/Point" },
      "p2": { "$ref": "#/definitions/Point" },
    },
  }
  let validator = build_validator(raw_schema)
  validator
  .validate({ "p1": { "x": 1, "y": 2 }, "p2": { "x": 3, "y": 4 } })
  .unwrap()
  |> inspect(content="()")
  validator
  .validate({ "p1": { "x": 1, "y": 2 }, "p3": { "x": 3, "y": 4 } })
  .unwrap_err()
  |> inspect(
    content=(
      #|[{input: Object({"p1": Object({"x": Number(1), "y": Number(2)}), "p3": Object({"x": Number(3), "y": Number(4)})}), json_path: #/p2, schema_path: #/required, message: "Required property 'p2' is missing", children: None}, {input: Object({"p1": Object({"x": Number(1), "y": Number(2)}), "p3": Object({"x": Number(3), "y": Number(4)})}), json_path: #/p3, schema_path: #/additionalProperties, message: "Additional property '{\"p3\"}' is not allowed", children: None}]
    ),
  )
}

///|
test "validate by schema builder" {
  let schema = JsonSchema::object(properties={ "v": JsonSchema::string() }, required=[
    "v",
  ])
  schema.validate({ "v": "test" }) |> assert_ok
}

///|
test "validate by schema builder with custome resolver" {
  let schema = JsonSchema::object(
    properties={
      "p1": JsonSchema::ref_("#/definitions/Point"),
      "p2": JsonSchema::ref_("#/definitions/Point"),
    },
    required=["p1", "p2"],
  )
  let validator = Validator::with_resolver(schema, fn(_p) {
    if _p == "#/definitions/Point" {
      Some(
        JsonSchema::object(
          properties={ "x": JsonSchema::integer(), "y": JsonSchema::integer() },
          required=["x", "y"],
        ),
      )
    } else {
      None
    }
  })
  validator.validate({ "p1": { "x": 1, "y": 2 }, "p2": { "x": 3, "y": 4 } })
  |> assert_ok
  validator
  .validate({ "p1": { "x": 1, "y": 2 }, "p3": { "x": 3, "y": 4 } })
  .unwrap_err()
  |> inspect(
    content=(
      #|[{input: Object({"p1": Object({"x": Number(1), "y": Number(2)}), "p3": Object({"x": Number(3), "y": Number(4)})}), json_path: #/p2, schema_path: #/required, message: "Required property 'p2' is missing", children: None}, {input: Object({"p1": Object({"x": Number(1), "y": Number(2)}), "p3": Object({"x": Number(3), "y": Number(4)})}), json_path: #/p3, schema_path: #/additionalProperties, message: "Additional property '{\"p3\"}' is not allowed", children: None}]
    ),
  )
}
