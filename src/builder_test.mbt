///|
test "parse object" {
  let input =
    #|{
    #|  "type": "object",
    #|  "properties": {
    #|    "name": { "type": "string" },
    #|    "age": { "type": "number" }
    #|  },
    #|  "required": ["name", "age"]
    #|}
  let jsonschema : Json = @json.parse(input)
  let schema : @jsonschema.Schema = @json.from_json(jsonschema)
  schema.validate({ "name": "Alice", "age": 30.0 }).unwrap()
  |> inspect(content="()")
  schema.validate({ "name": 42, "age": 30.0 }).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: $.name, schema_path: $.properties.name, message: "Number(42) is not a string"}]
    ),
  )
  schema.to_json().to_string()
  |> inspect(
    content=(
      #|Object({"type": String("object"), "properties": Object({"name": Object({"type": String("string")}), "age": Object({"type": String("number")})}), "required": Array([String("name"), String("age")])})
    ),
  )
  ()
}

///|
test "parse array" {
  let input =
    #|{
    #|  "type": "array",
    #|  "items": { "type": "string" }
    #|}
  let jsonschema : Json = @json.parse(input)
  let schema : @jsonschema.Schema = @json.from_json(jsonschema)
  schema.validate(["a", "b"]).unwrap() |> inspect(content="()")
  schema.validate(["a", 1]).unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: $[1], schema_path: $.items, message: "Number(1) is not a string"}]
    ),
  )
}

///|
test "parse nested" {
  let input =
    #|{
    #|  "type": "object",
    #|  "properties": {
    #|    "name": { "type": "string" },
    #|    "age": { "type": "integer" },
    #|    "friends": { "type": "array", "items": { "type": "string" } },
    #|    "nullValue": { "type": "null" },
    #|    "anyValue": { "type": "any" }
    #|  },
    #|  "required": ["name", "age", "friends", "nullValue", "anyValue"]
    #|}
  let jsonschema : Json = @json.parse(input)
  let schema : @jsonschema.Schema = @json.from_json(jsonschema)
  schema
  .validate({
    "name": "Alice",
    "age": 30,
    "friends": ["Bob"],
    "nullValue": null,
    "anyValue": "anything",
  })
  .unwrap()
  |> inspect(content="()")
  schema
  .validate({
    "name": "Alice",
    "age": 30,
    "friends": [1],
    "nullValue": null,
    "anyValue": "anything",
  })
  .unwrap_err()
  |> inspect(
    content=(
      #|[{json_path: $.friends[0], schema_path: $.properties.friends.items, message: "Number(1) is not a string"}]
    ),
  )
}
