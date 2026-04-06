///|
test "validate simple object" (b : @bench.T) {
  let raw =
    #|{
    #|  "type": "object",
    #|  "properties": {
    #|    "name": { "type": "string" },
    #|    "age": { "type": "number" }
    #|  },
    #|  "required": ["name", "age"]
    #|}
  let validator = try! build_validator(try! @json.parse(raw))
  let input : Json = { "name": "Alice", "age": 30.0 }
  b.bench(() => b.keep(validator.validate(input)))
}

///|
test "validate nested object" (b : @bench.T) {
  let raw =
    #|{
    #|  "type": "object",
    #|  "properties": {
    #|    "user": {
    #|      "type": "object",
    #|      "properties": {
    #|        "name": { "type": "string" },
    #|        "email": { "type": "string" }
    #|      },
    #|      "required": ["name", "email"]
    #|    },
    #|    "tags": {
    #|      "type": "array",
    #|      "items": { "type": "string" }
    #|    }
    #|  },
    #|  "required": ["user"]
    #|}
  let validator = try! build_validator(try! @json.parse(raw))
  let input : Json = {
    "user": { "name": "Alice", "email": "alice@example.com" },
    "tags": ["admin", "user"],
  }
  b.bench(() => b.keep(validator.validate(input)))
}

///|
test "validate failure path" (b : @bench.T) {
  let raw =
    #|{
    #|  "type": "object",
    #|  "properties": {
    #|    "name": { "type": "string", "minLength": 1 },
    #|    "age": { "type": "integer", "minimum": 0, "maximum": 150 },
    #|    "email": { "type": "string" }
    #|  },
    #|  "required": ["name", "age", "email"]
    #|}
  let validator = try! build_validator(try! @json.parse(raw))
  let bad_input : Json = { "name": 42, "age": "not-a-number" }
  b.bench(() => b.keep(validator.validate(bad_input)))
}

///|
test "validate with $ref" (b : @bench.T) {
  let raw =
    #|{
    #|  "definitions": {
    #|    "Point": {
    #|      "type": "object",
    #|      "required": ["x", "y"],
    #|      "properties": {
    #|        "x": { "type": "integer" },
    #|        "y": { "type": "integer" }
    #|      }
    #|    }
    #|  },
    #|  "type": "object",
    #|  "required": ["p1", "p2"],
    #|  "properties": {
    #|    "p1": { "$ref": "#/definitions/Point" },
    #|    "p2": { "$ref": "#/definitions/Point" }
    #|  }
    #|}
  let validator = try! build_validator(try! @json.parse(raw))
  let input : Json = { "p1": { "x": 1, "y": 2 }, "p2": { "x": 3, "y": 4 } }
  b.bench(() => b.keep(validator.validate(input)))
}

///|
test "validate large array" (b : @bench.T) {
  let bld = Builder::new()
  let schema = bld.array(items=bld.integer(minimum=0, maximum=1000))
  let resolver = build_resolver({})
  let items : Array[Json] = Array::makei(100, i => Json::number(i.to_double()))
  let input : Json = Json::array(items)
  b.bench(() => {
    b.keep(
      schema.validate(
        input,
        resolver~,
        json_path=JsonPointer::Root,
        schema_path=JsonPointer::Root,
      ),
    )
  })
}

///|
test "validate oneOf" (b : @bench.T) {
  let bld = Builder::new()
  let schema = bld.one_of([
    bld.object(properties={ "type": bld.const_("a"), "value": bld.string() }, required=[
      "type", "value",
    ]),
    bld.object(properties={ "type": bld.const_("b"), "value": bld.integer() }, required=[
      "type", "value",
    ]),
    bld.object(properties={ "type": bld.const_("c"), "value": bld.number() }, required=[
      "type", "value",
    ]),
  ])
  let resolver = build_resolver({})
  let input : Json = { "type": "b", "value": 42 }
  b.bench(() => {
    b.keep(
      schema.validate(
        input,
        resolver~,
        json_path=JsonPointer::Root,
        schema_path=JsonPointer::Root,
      ),
    )
  })
}

///|
test "build and parse schema" (b : @bench.T) {
  let raw =
    #|{
    #|  "type": "object",
    #|  "properties": {
    #|    "name": { "type": "string", "minLength": 1 },
    #|    "age": { "type": "integer", "minimum": 0, "maximum": 150 },
    #|    "tags": { "type": "array", "items": { "type": "string" } }
    #|  },
    #|  "required": ["name", "age"]
    #|}
  b.bench(() => b.keep(try! build_validator(try! @json.parse(raw))))
}
