// JSON Schema Validator tests

///|
test "validate string type" {
  let schema = Schema::string()
  let validator = Validator::new(schema)

  // Valid string
  let result1 = validator.validate(Json::string("hello"))
  inspect(result1, content="Ok")

  // Invalid - number instead of string
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Json::number(42.0))
  match result2 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "validate number constraints" {
  let schema = Schema::number_with_constraints(
    Some(0.0), // minimum
    Some(100.0), // maximum
    None, // exclusive_minimum
    None, // exclusive_maximum
    None, // multiple_of
  )
  let validator = Validator::new(schema)

  // Valid number
  let result1 = validator.validate(Json::number(50.0))
  inspect(result1, content="Ok")

  // Too small
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Json::number(-10.0))
  match result2 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }

  // Too large
  let validator3 = Validator::new(schema)
  let result3 = validator3.validate(Json::number(150.0))
  match result3 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "validate array constraints" {
  let schema = Schema::array_with_constraints(
    None, // items
    Some(1), // min_items
    Some(3), // max_items
    None, // unique_items
  )
  let validator = Validator::new(schema)

  // Valid array
  let arr : Array[Json] = []
  arr.push(Json::string("a"))
  arr.push(Json::string("b"))
  let result1 = validator.validate(Json::array(arr))
  inspect(result1, content="Ok")

  // Empty array (too small)
  let validator2 = Validator::new(schema)
  let empty_arr : Array[Json] = []
  let result2 = validator2.validate(Json::array(empty_arr))
  match result2 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "validate object with required properties" {
  let props = Map::new()
  props.set("name", Schema::string())
  props.set("age", Schema::number())
  let schema = Schema::object(Some(props), Some(["name", "age"]))
  let validator = Validator::new(schema)

  // Valid object
  let obj : Map[String, Json] = Map::new()
  obj.set("name", Json::string("John"))
  obj.set("age", Json::number(30.0))
  let result1 = validator.validate(Json::object(obj))
  inspect(result1, content="Ok")

  // Missing required property
  let validator2 = Validator::new(schema)
  let obj2 : Map[String, Json] = Map::new()
  obj2.set("name", Json::string("Jane"))
  let result2 = validator2.validate(Json::object(obj2))
  match result2 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "validate enum values" {
  let enum_values : Array[Json] = []
  enum_values.push(Json::string("red"))
  enum_values.push(Json::string("green"))
  enum_values.push(Json::string("blue"))
  let schema = Schema::enum_values(enum_values)
  let validator = Validator::new(schema)

  // Valid enum value
  let result1 = validator.validate(Json::string("red"))
  inspect(result1, content="Ok")

  // Invalid enum value
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Json::string("yellow"))
  match result2 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "validate null type" {
  let schema = Schema::null()
  let validator = Validator::new(schema)

  // Valid null
  let result1 = validator.validate(Json::null())
  inspect(result1, content="Ok")

  // Invalid - string instead of null
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Json::string("not null"))
  match result2 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "validate boolean type" {
  let schema = Schema::boolean()
  let validator = Validator::new(schema)

  // Valid boolean
  let result1 = validator.validate(Json::boolean(true))
  inspect(result1, content="Ok")
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Json::boolean(false))
  inspect(result2, content="Ok")

  // Invalid - number instead of boolean
  let validator3 = Validator::new(schema)
  let result3 = validator3.validate(Json::number(1.0))
  match result3 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "validate const value" {
  let const_val = Json::string("constant")
  let schema = Schema::const_value(const_val)
  let validator = Validator::new(schema)

  // Valid - exact match
  let result1 = validator.validate(Json::string("constant"))
  inspect(result1, content="Ok")

  // Invalid - different value
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Json::string("different"))
  match result2 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

// Multiple types test is skipped due to SchemaType enum constructor limitations

///|
test "validate any type" {
  let schema = Schema::any()
  let validator = Validator::new(schema)

  // All types should be valid
  inspect(validator.validate(Json::null()), content="Ok")
  let validator2 = Validator::new(schema)
  inspect(validator2.validate(Json::boolean(true)), content="Ok")
  let validator3 = Validator::new(schema)
  inspect(validator3.validate(Json::string("any")), content="Ok")
  let validator4 = Validator::new(schema)
  inspect(validator4.validate(Json::number(123.0)), content="Ok")
}

///|
test "parse schema from json - string type" {
  let schema_json : Json = Json::object(
    Map::of([
      ("type", Json::string("string")),
      ("minLength", Json::number(3.0)),
      ("maxLength", Json::number(10.0)),
    ]),
  )
  let schema : Schema = @json.from_json(schema_json)
  let validator = Validator::new(schema)

  // Valid string
  let result1 = validator.validate(Json::string("hello"))
  inspect(result1, content="Ok")

  // Too short
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Json::string("hi"))
  match result2 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "parse schema from json - number with constraints" {
  let schema_json = Json::object(
    Map::of([
      ("type", Json::string("number")),
      ("minimum", Json::number(0.0)),
      ("maximum", Json::number(100.0)),
    ]),
  )
  let schema : Schema = @json.from_json(schema_json)
  let validator = Validator::new(schema)

  // Valid number
  let result1 = validator.validate(Json::number(50.0))
  inspect(result1, content="Ok")

  // Too large
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Json::number(150.0))
  match result2 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "parse schema from json - object with properties" {
  let schema : Schema = @json.from_json({
    "type": "object",
    "required": ["name"],
    "properties": { "name": { "type": "string" }, "age": { "type": "number" } },
    "required": ["name"],
  })
  let validator = Validator::new(schema)

  // Valid object
  let obj : Json = { "name": "Alice", "age": 30.0 }
  let result1 = validator.validate(obj)
  inspect(result1, content="Ok")

  // Missing required property
  let validator2 = Validator::new(schema)
  let obj2 : Json = { "age": 25.0 }
  let result2 = validator2.validate(obj2)
  match result2 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "parse schema from json - anyOf" {
  let schema : Schema = @json.from_json({
    "anyOf": [{ "type": "string" }, { "type": "number" }],
  })
  let validator = Validator::new(schema)

  // Valid - string
  let result1 = validator.validate(Json::string("hello"))
  inspect(result1, content="Ok")

  // Valid - number
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Json::number(42.0))
  inspect(result2, content="Ok")

  // Invalid - boolean
  let validator3 = Validator::new(schema)
  let result3 = validator3.validate(Json::boolean(true))
  match result3 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "parse schema from json - enum" {
  let enum_array : Json = { "enum": ["red", "green", "blue"] }
  let schema : Schema = @json.from_json(enum_array)
  let validator = Validator::new(schema)

  // Valid enum value
  let result1 = validator.validate(Json::string("red"))
  inspect(result1, content="Ok")

  // Invalid enum value
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Json::string("yellow"))
  match result2 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "parse schema from json - boolean schema" {
  // true schema allows any value
  let schema1 : Schema = @json.from_json({ "type": "boolean" })
  let validator1 = Validator::new(schema1)
  inspect(validator1.validate(Json::boolean(true)), content="Ok")
  inspect(validator1.validate(Json::boolean(false)), content="Ok")
  inspect(
    validator1.validate(Json::string("oooo")),
    content=(
      #|Err([{path: "$", message: "Value is not a boolean", schema_path: "#"}])
    ),
  )
}

///|
test "format errors for human output" {
  let schema = Schema::object(
    Some(Map::of([("name", Schema::string()), ("age", Schema::number())])),
    Some(["name", "age"]),
  )
  let validator = Validator::new(schema)

  // Invalid object - missing required properties
  let obj = Map::of([("email", Json::string("test@example.com"))])
  let result = validator.validate(Json::object(obj))
  match result {
    ValidationResult::Err(errors) => {
      let formatted = format_errors(errors)
      // Check that formatted string contains expected content
      assert_true(formatted.contains("Validation failed"))
      assert_true(formatted.contains("Required property"))
      assert_true(formatted.contains("name"))
      assert_true(formatted.contains("age"))
    }
    ValidationResult::Ok => assert_false(true)
  }
}

///|
test "immutable validator reuse" {
  let schema = Schema::number_with_constraints(
    Some(0.0),
    Some(100.0),
    None,
    None,
    None,
  )
  let validator = Validator::new(schema)

  // Use the same validator multiple times
  let result1 = validator.validate(Json::number(50.0))
  inspect(result1, content="Ok")
  let result2 = validator.validate(Json::number(150.0))
  match result2 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }

  // Validator can still be used after errors
  let result3 = validator.validate(Json::number(25.0))
  inspect(result3, content="Ok")
}

///|
test "validate anyOf schemas" {
  let string_schema = Schema::string()
  let number_schema = Schema::number()
  let schemas : Array[Schema] = []
  schemas.push(string_schema)
  schemas.push(number_schema)
  let schema = Schema::any_of(schemas)
  let validator = Validator::new(schema)

  // Valid - string
  let result1 = validator.validate(Json::string("hello"))
  inspect(result1, content="Ok")

  // Valid - number
  let validator2 = Validator::new(schema)
  let result2 = validator2.validate(Json::number(42.0))
  inspect(result2, content="Ok")

  // Invalid - boolean
  let validator3 = Validator::new(schema)
  let result3 = validator3.validate(Json::boolean(true))
  match result3 {
    ValidationResult::Err(errors) => assert_true(errors.length() > 0)
    ValidationResult::Ok => assert_false(true)
  }
}
