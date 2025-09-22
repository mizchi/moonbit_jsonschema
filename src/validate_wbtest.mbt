// JSON Schema Validator tests

///|
test "validate null" {
  let schema = Schema::null()
  schema.validate(null).unwrap() |> inspect(content="()")
  schema.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #, message: "Number(1) is not null", children: None}]
    ),
  )
}

///|
test "validate const" {
  let schema = Schema::const_(Json::string("constant"))
  schema.validate("constant").unwrap() |> inspect(content="()")
  schema.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #, message: "Number(1) does not match constant value String(\"constant\")", children: None}]
    ),
  )
}

///|
test "validate const nested" {
  let schema = Schema::const_({ "nested": true })
  schema.validate({ "nested": true }).unwrap() |> inspect(content="()")
  schema.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #, message: "Number(1) does not match constant value Object({\"nested\": True})", children: None}]
    ),
  )
}

///|
test "validate any" {
  let schema = Schema::any()
  schema.validate(null).unwrap() |> inspect(content="()")
  schema.validate({}).unwrap() |> inspect(content="()")
}

///|
test "validate string" {
  let schema = Schema::string()
  schema.validate("hello").unwrap() |> inspect(content="()")
  schema.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #, message: "Number(1) is not a string", children: None}]
    ),
  )
}

///|
test "validate string with enum" {
  let schema = Schema::string(enum_=["a", "b"])
  schema.validate("a").unwrap() |> inspect(content="()")
  schema.validate("b").unwrap() |> inspect(content="()")
  schema.validate("c").unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #/enum, message: "c is not in [\"a\", \"b\"]", children: None}]
    ),
  )
}

///|
test "validate string type with minLength and maxLength" {
  let schema = Schema::string(minLength=3, maxLength=5)
  schema.validate("hey").unwrap() |> inspect(content="()")
  schema.validate("hi").unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #/minLength, message: "String length 2 is less than minimum 3", children: None}]
    ),
  )
  match schema.validate("hellooo") {
    Ok(_) => panic()
    Err(errors) =>
      inspect(
        errors,
        content=(
          #|[{json_path: #, schema_path: #/maxLength, message: "String length 7 is greater than maximum 5", children: None}]
        ),
      )
  }
}

///|
test "validate enum" {
  let schema = Schema::enum_(["red", "green", "blue"])
  schema.validate("red").unwrap() |> inspect(content="()")
  schema.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #, message: "Number(1) is not in [String(\"red\"), String(\"green\"), String(\"blue\")]", children: None}]
    ),
  )
  schema.validate("yellow").unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #, message: "String(\"yellow\") is not in [String(\"red\"), String(\"green\"), String(\"blue\")]", children: None}]
    ),
  )
}

///|
test "validate number" {
  let schema = Schema::number(minimum=0.0, maximum=100.0)
  schema.validate(0).unwrap() |> inspect(content="()")
  schema.validate(1.1).unwrap() |> inspect(content="()")
}

///|
test "validate number with constraints" {
  let schema = Schema::number(minimum=0.0, maximum=100.0)
  schema.validate(0).unwrap() |> inspect(content="()")
  schema.validate(1).unwrap() |> inspect(content="()")
  schema.validate(100).unwrap() |> inspect(content="()")
  schema.validate(-10).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #/minimum, message: "-10 is less than minimum 0", children: None}]
    ),
  )
  schema.validate("invalid").unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #, message: "Value is not a number", children: None}]
    ),
  )
}

///|
test "validate integer" {
  let schema = Schema::integer()
  schema.validate(0).unwrap() |> inspect(content="()")
  schema.validate(1.1).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #, message: "1.1 is not an integer", children: None}]
    ),
  )
  schema.validate(1.0).unwrap() |> inspect(content="()")
}

///|
test "validate integer with constraints" {
  let schema = Schema::integer(minimum=0, maximum=10)
  schema.validate(0).unwrap() |> inspect(content="()")
  schema.validate(1).unwrap() |> inspect(content="()")
  schema.validate(10).unwrap() |> inspect(content="()")
  schema.validate(-10).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #/minimum, message: "-10 is less than minimum 0", children: None}]
    ),
  )
  schema.validate("invalid").unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #, message: "String(\"invalid\") is not a number", children: None}]
    ),
  )
}

///|
test "validate object" {
  let schema = Schema::object(properties={ "name": Schema::string() }, required=[
    "name",
  ])
  // println(schema)
  schema.validate({ "name": "John" }).unwrap() |> inspect(content="()")
  schema.validate({ "name": 0 }).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #/name, schema_path: #/properties/name, message: "Number(0) is not a string", children: None}]
    ),
  )
  // no required
  schema.validate({}).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #/name, schema_path: #/required, message: "Required property 'name' is missing", children: None}]
    ),
  )
  let schema_no_required = Schema::object(properties={
    "name": Schema::string(),
  })
  schema_no_required.validate({}).unwrap() |> inspect(content="()")
  schema_no_required.validate({ "name": "foo" }).unwrap()
  |> inspect(content="()")
  schema_no_required.validate({ "name": 1 }).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #/name, schema_path: #/properties/name, message: "Number(1) is not a string", children: None}]
    ),
  )
}

///|
test "additionalProperties" {
  let schema = Schema::object(
    properties={ "name": Schema::string() },
    required=["name"],
    additionalProperties=false,
  )
  schema.validate({ "name": "John" }).unwrap() |> inspect(content="()")
  schema.validate({ "name": "John", "notAllowd": true, "no": 2 }).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #/notAllowd, schema_path: #/additionalProperties, message: "Additional property '[\"notAllowd\", \"no\"]' is not allowed", children: None}, {json_path: #/no, schema_path: #/additionalProperties, message: "Additional property '[\"notAllowd\", \"no\"]' is not allowed", children: None}]
    ),
  )
}

///|
test "validate array" {
  let schema = Schema::array(
    items=Schema::object(properties={ "id": Schema::integer() }, required=["id"]),
  )
  schema.validate([]).unwrap() |> inspect(content="()")
  schema.validate([{ "id": 1 }]).unwrap() |> inspect(content="()")
  schema.validate([{ "id": 1 }, { "id": "not-allowed" }]).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #/1/id, schema_path: #/items/properties/id, message: "String(\"not-allowed\") is not a number", children: None}]
    ),
  )
}

///|
test "validate array with constraints" {
  let schema = Schema::array(items=Schema::integer(), minItems=1, maxItems=3)
  schema.validate([]).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #/minItems, message: "Array length 0 is less than minimum 1", children: None}]
    ),
  )
  schema.validate([1]).unwrap() |> inspect(content="()")
  schema.validate([1, 2, 3, 4]).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #/maxItems, message: "Array length 4 is greater than maximum 3", children: None}]
    ),
  )
}

///|
test "validate oneOf" {
  let schema = Schema::oneOf([Schema::string()])
  schema.validate("hello").unwrap() |> inspect(content="()")
  let schema = Schema::oneOf([Schema::string(), Schema::null()])
  schema.validate("hello").unwrap() |> inspect(content="()")
  schema.validate(null).unwrap() |> inspect(content="()")
  schema.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #/oneOf/0, message: "Number(1) is not a string", children: None}, {json_path: #, schema_path: #/oneOf/1, message: "Number(1) is not null", children: None}, {json_path: #, schema_path: #/oneOf, message: "Number(1) does not match exactly one schema in oneOf", children: None}]
    ),
  )
}

///|
test "validate allOf" {
  let schema = Schema::allOf([Schema::string()])
  schema.validate("hello").unwrap() |> inspect(content="()")
  let schema2 = Schema::allOf([Schema::string(), Schema::const_("foo")])
  schema2.validate("foo").unwrap() |> inspect(content="()")
  schema2.validate("bar").unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #/oneOf/1, message: "String(\"bar\") does not match constant value String(\"foo\")", children: None}, {json_path: #, schema_path: #/allOf, message: "String(\"bar\") does not match exactly one schema in allOf", children: None}]
    ),
  )
}

///|
test "validate anyOf" {
  let schema = Schema::anyOf([Schema::string()])
  schema.validate("hello").unwrap() |> inspect(content="()")
  let schema2 = Schema::anyOf([Schema::string(), Schema::const_("foo")])
  schema2.validate("foo").unwrap() |> inspect(content="()")
  schema2.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #/anyOf/0, message: "Number(1) is not a string", children: None}, {json_path: #, schema_path: #/anyOf/1, message: "Number(1) does not match constant value String(\"foo\")", children: None}, {json_path: #, schema_path: #/anyOf, message: "Number(1) does not match any schema in anyOf", children: None}]
    ),
  )
  let schema3 = Schema::anyOf([
    Schema::string(),
    Schema::const_("foo"),
    Schema::null(),
  ])
  schema3.validate(null).unwrap() |> inspect(content="()")
  schema3.validate("foo").unwrap() |> inspect(content="()")
  schema3.validate("bar").unwrap() |> inspect(content="()")
  schema3.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #/anyOf/0, message: "Number(1) is not a string", children: None}, {json_path: #, schema_path: #/anyOf/1, message: "Number(1) does not match constant value String(\"foo\")", children: None}, {json_path: #, schema_path: #/anyOf/2, message: "Number(1) is not null", children: None}, {json_path: #, schema_path: #/anyOf, message: "Number(1) does not match any schema in anyOf", children: None}]
    ),
  )
}

///|
test "validate $ref" {
  let raw_schema : Json = {
    "definitions": { "PositiveInteger": { "type": "integer", "minimum": 0 } },
    "$ref": "#/definitions/PositiveInteger",
  }
  let validator = Validator::from_json(raw_schema)
  validator.validate(5).unwrap() |> inspect(content="()")
  validator.validate("err").unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #, schema_path: #/$ref, message: "String(\"err\") is not a number", children: None}]
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
  let validator = Validator::from_json(raw_schema)
  validator.validate([{ "x": 1, "y": 2 }]).unwrap() |> inspect(content="()")
  validator.validate([{ "x": "err", "y": 2 }]).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #/0/x, schema_path: #/items/$ref/properties/x, message: "String(\"err\") is not a number", children: None}]
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
  let validator = Validator::from_json(raw_schema)
  validator
  .validate({ "p1": { "x": 1, "y": 2 }, "p2": { "x": 3, "y": 4 } })
  .unwrap()
  |> inspect(content="()")
  validator
  .validate({ "p1": { "x": 1, "y": 2 }, "p3": { "x": 3, "y": 4 } })
  .unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: #/p2, schema_path: #/required, message: "Required property 'p2' is missing", children: None}]
    ),
  )
}
