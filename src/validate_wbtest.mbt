// JSON Schema Validator tests

///|
test "validate null" {
  let schema = Schema::null()
  schema.validate(null).unwrap() |> inspect(content="()")
  schema.validate(1).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: $, schema_path: $, message: "Number(1) is not null"}]
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
      #|[{json_path: $, schema_path: $, message: "Number(1) is not a string"}]
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
      #|[{json_path: $, schema_path: $.enum, message: "c is not in [\"a\", \"b\"]"}]
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
      #|[{json_path: $, schema_path: $.minLength, message: "String length 2 is less than minimum 3"}]
    ),
  )
  match schema.validate("hellooo") {
    Ok(_) => panic()
    Err(errors) =>
      inspect(
        errors,
        content=(
          #|[{json_path: $, schema_path: $.maxLength, message: "String length 7 is greater than maximum 5"}]
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
      #|[{json_path: $, schema_path: $, message: "Number(1) is not in [String(\"red\"), String(\"green\"), String(\"blue\")]"}]
    ),
  )
  schema.validate("yellow").unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: $, schema_path: $, message: "String(\"yellow\") is not in [String(\"red\"), String(\"green\"), String(\"blue\")]"}]
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
      #|[{json_path: $, schema_path: $.minimum, message: "-10 is less than minimum 0"}]
    ),
  )
  schema.validate("invalid").unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: $, schema_path: $, message: "Value is not a number"}]
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
      #|[{json_path: $, schema_path: $, message: "1.1 is not an integer"}]
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
      #|[{json_path: $, schema_path: $.minimum, message: "-10 is less than minimum 0"}]
    ),
  )
  schema.validate("invalid").unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: $, schema_path: $, message: "String(\"invalid\") is not a number"}]
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
      #|[{json_path: $.name, schema_path: $.properties.name, message: "Number(0) is not a string"}]
    ),
  )
  // no required
  schema.validate({}).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: $.name, schema_path: $.required, message: "Required property 'name' is missing"}]
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
      #|[{json_path: $.name, schema_path: $.properties.name, message: "Number(1) is not a string"}]
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
      #|[{json_path: $.notAllowd, schema_path: $.additionalProperties, message: "Additional property '[\"notAllowd\", \"no\"]' is not allowed"}, {json_path: $.no, schema_path: $.additionalProperties, message: "Additional property '[\"notAllowd\", \"no\"]' is not allowed"}]
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
      #|[{json_path: $[1].id, schema_path: $.items.properties.id, message: "String(\"not-allowed\") is not a number"}]
    ),
  )
}

///|
test "validate array with constraints" {
  let schema = Schema::array(items=Schema::integer(), minItems=1, maxItems=3)
  schema.validate([]).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: $, schema_path: $.minItems, message: "Array length 0 is less than minimum 1"}]
    ),
  )
  schema.validate([1]).unwrap() |> inspect(content="()")
  schema.validate([1, 2, 3, 4]).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: $, schema_path: $.maxItems, message: "Array length 4 is greater than maximum 3"}]
    ),
  )
}

// ///|
// // test "validate null type" {
// //   let schema = Schema::Null

// //   // Valid null
// //   let result1 = schema.validate(Json::null())
// //   inspect(result1, content="Ok")

// //   // Invalid - string instead of null
// //   let result2 = schema.validate(Json::string("not null"))
// //   match result2 {
// //     Err(errors) => assert_true(errors.length() > 0)
// //     Ok(_) => assert_false(true)
// //   }
// // }

// ///|
// test "validate boolean type" {
//   let schema : Schema = Schema::boolean()

//   // Valid boolean
//   let result1 = schema.validate(Json::boolean(true))
//   inspect(result1, content="Ok(())")
//   let result2 = schema.validate(Json::boolean(false))
//   inspect(result2, content="Ok(())")

//   // Invalid - number instead of boolean
//   let result3 = schema.validate(Json::number(1.0))
//   match result3 {
//     Err(errors) => assert_true(errors.length() > 0)
//     Ok(_) => assert_true(false)
//   }
// }

// ///|
// // test "validate const value" {
// //   let const_val = Json::string("constant")
// //   let schema = Schema::Const(const_val)
// //   let validator = Validator::new(schema)

// //   // Valid - exact match
// //   let result1 = schema.validate(Json::string("constant"))
// //   inspect(result1, content="Ok")

// //   // Invalid - different value
// //   let validator2 = Validator::new(schema)
// //   let result2 = validator2.validate(Json::string("different"))
// //   match result2 {
// //     Err(errors) => assert_true(errors.length() > 0)
// //     Ok(_) => assert_false(true)
// //   }
// // }

// // Multiple types test is skipped due to SchemaType enum constructor limitations

// ///|
// test "validate any type" {
//   let schema = Schema::any()
//   // All types should be valid
//   inspect(schema.validate(Json::null()), content="Ok(())")
//   inspect(schema.validate(Json::boolean(true)), content="Ok(())")
//   inspect(schema.validate(Json::string("any")), content="Ok(())")
//   inspect(schema.validate(Json::number(123.0)), content="Ok(())")
// }

// ///|
// test "parse schema from json - string type" {
//   let schema_json : Json = Json::object(
//     Map::of([
//       ("type", Json::string("string")),
//       ("minLength", Json::number(3.0)),
//       ("maxLength", Json::number(10.0)),
//     ]),
//   )
//   let schema : Schema = @json.from_json(schema_json)

//   // Valid string
//   let result1 = schema.validate(Json::string("hello"))
//   inspect(result1, content="Ok(())")

//   // Too short
//   let result2 = schema.validate(Json::string("hi"))
//   match result2 {
//     Err(errors) => assert_true(errors.length() > 0)
//     Ok(_) => assert_false(true)
//   }
// }

// ///|
// test "parse schema from json - number with constraints" {
//   let schema_json = Json::object(
//     Map::of([
//       ("type", Json::string("number")),
//       ("minimum", Json::number(0.0)),
//       ("maximum", Json::number(100.0)),
//     ]),
//   )
//   let schema : Schema = @json.from_json(schema_json)

//   // Valid number
//   let result1 = schema.validate(Json::number(50.0))
//   inspect(result1, content="Ok(())")

//   // Too large
//   let result2 = schema.validate(Json::number(150.0))
//   match result2 {
//     Err(errors) => assert_true(errors.length() > 0)
//     Ok(_) => assert_false(true)
//   }
// }

// ///|
// test "parse schema from json - object with properties" {
//   let schema : Schema = @json.from_json({
//     "type": "object",
//     "required": ["name"],
//     "properties": { "name": { "type": "string" }, "age": { "type": "number" } },
//     "required": ["name"],
//   })

//   // Valid object
//   let obj : Json = { "name": "Alice", "age": 30.0 }
//   let result1 = schema.validate(obj)
//   inspect(result1, content="Ok(())")

//   // Missing required property
//   let obj2 : Json = { "age": 25.0 }
//   let result2 = schema.validate(obj2)
//   match result2 {
//     Err(errors) => assert_true(errors.length() > 0)
//     Ok(_) => assert_false(true)
//   }
// }

// ///|
// test "parse schema from json - anyOf" {
//   let schema : Schema = @json.from_json({
//     "anyOf": [{ "type": "string" }, { "type": "number" }],
//   })

//   // Valid - string
//   let result1 = schema.validate(Json::string("hello"))
//   inspect(result1, content="Ok")

//   // Valid - number
//   let result2 = schema.validate(Json::number(42.0))
//   inspect(result2, content="Ok")

//   // Invalid - boolean
//   let result3 = schema.validate(Json::boolean(true))
//   match result3 {
//     Err(errors) => assert_true(errors.length() > 0)
//     Ok(_) => assert_false(true)
//   }
// }

// ///|
// test "parse schema from json - enum" {
//   let enum_array : Json = { "enum": ["red", "green", "blue"] }
//   let schema : Schema = @json.from_json(enum_array)

//   // Valid enum value
//   let result1 = schema.validate(Json::string("red"))
//   inspect(result1, content="Ok")

//   // Invalid enum value
//   let result2 = schema.validate(Json::string("yellow"))
//   match result2 {
//     Err(errors) => assert_true(errors.length() > 0)
//     Ok(_) => assert_false(true)
//   }
// }

// ///|
// test "parse schema from json - boolean schema" {
//   // true schema allows any value
//   let schema1 : Schema = @json.from_json({ "type": "boolean" })
//   inspect(schema1.validate(Json::boolean(true)), content="Ok(())")
//   inspect(schema1.validate(Json::boolean(false)), content="Ok(())")
//   inspect(
//     schema1.validate(Json::string("oooo")),
//     content=(
//       #|Err([{json_path: $, schema_path: $, message: "Value is not a boolean"}])

//     ),
//   )
// }

// ///|
// // test "format errors for human output" {
// //   let schema = Schema::object(
// //     Some(Map::of([("name", Schema::string()), ("age", Schema::number())])),
// //     Some(["name", "age"]),
// //   )
// //   let validator = Validator::new(schema)

// //   // Invalid object - missing required properties
// //   let obj = Map::of([("email", Json::string("test@example.com"))])
// //   let result = schema.validate(Json::object(obj))
// //   match result {
// //     Err(errors) => {
// //       let formatted = format_errors(errors)
// //       // Check that formatted string contains expected content
// //       assert_true(formatted.contains("Validation failed"))
// //       assert_true(formatted.contains("Required property"))
// //       assert_true(formatted.contains("name"))
// //       assert_true(formatted.contains("age"))
// //     }
// //     Ok(_) => assert_false(true)
// //   }
// // }

// // ///|
// // test "immutable validator reuse" {
// //   let schema = Schema::number_with_constraints(
// //     Some(0.0),
// //     Some(100.0),
// //     None,
// //     None,
// //     None,
// //   )
// //   let validator = Validator::new(schema)

// //   // Use the same validator multiple times
// //   let result1 = schema.validate(Json::number(50.0))
// //   inspect(result1, content="Ok")
// //   let result2 = schema.validate(Json::number(150.0))
// //   match result2 {
// //     Err(errors) => assert_true(errors.length() > 0)
// //     Ok(_) => assert_false(true)
// //   }

// //   // Validator can still be used after errors
// //   let result3 = schema.validate(Json::number(25.0))
// //   inspect(result3, content="Ok")
// // }

// // ///|
// // test "validate anyOf schemas" {
// //   let string_schema = Schema::string()
// //   let number_schema = Schema::number()
// //   let schemas : Array[Schema] = []
// //   schemas.push(string_schema)
// //   schemas.push(number_schema)
// //   let schema = Schema::any_of(schemas)
// //   let validator = Validator::new(schema)

// //   // Valid - string
// //   let result1 = schema.validate(Json::string("hello"))
// //   inspect(result1, content="Ok")

// //   // Valid - number
// //   let validator2 = Validator::new(schema)
// //   let result2 = validator2.validate(Json::number(42.0))
// //   inspect(result2, content="Ok")

// //   // Invalid - boolean
// //   let validator3 = Validator::new(schema)
// //   let result3 = validator3.validate(Json::boolean(true))
// //   match result3 {
// //     Err(errors) => assert_true(errors.length() > 0)
// //     Ok(_) => assert_false(true)
// //   }
// // }
