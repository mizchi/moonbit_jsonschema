///|
test (b : @bench.T) {
  let jsonschema : Json = @json.parse(
    (
      #|{
      #|  "type": "object",
      #|  "properties": {
      #|    "name": { "type": "string" },
      #|    "age": { "type": "number" }
      #|  },
      #|  "required": ["name", "age"]
      #|}
    ),
  )
  let validator = Validator::from_json(jsonschema)
  b.bench(fn() {
    try {
      let _ = validator.validate({ "name": "Alice", "age": 30.0 })

    } catch {
      _ => ()
    }
  })
}
