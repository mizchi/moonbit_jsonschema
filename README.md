# @mizchi/jsonschema

```
$ moon add mizchi/jsonschema
```

## Example

```json:moon.pkg.json
{
  "import": [
    "mizchi/jsonschema"
  ]
}
```

```mbt
fn run() -> Unit raise {
  let schema : Json = { "type": "string" }
  let validator = @jsonschema.Validator::from_json(schema)
  match validator.validate(5) {
    Ok(_) => println("passed")
    Err(errors) => println("validation erros: \{errors}")
  }
}
```

## with builder

```
  let schema = JsonSchema::object(properties={ "v": JsonSchema::string() }, required=[
    "v",
  ])
  schema.validate({ "v": "test" })
```

NOTE: `Json => JsonSchema => Json` is not perfect yet. Some properties may be dropped.

## with builder and custome resolver

```mbt
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
```

## Supported

- [x] type: any
- [x] type: null
- [x] type: number
  - [x] minimum
  - [x] maximum
  - [x] exclusiveMinimum
  - [x] exclusiveMaximum
  - [ ] multipleOf
- [x] type: integer

  - [x] minimum
  - [x] maximum
  - [x] exclusiveMinimum
  - [x] exclusiveMaximum
  - [ ] multipleOf

- [x] type: string
  - [x] minLength
  - [x] maxLength
  - [x] enum
- [x] type: boolean
- [x] type: array
  - [x] items
  - [x] minItems
  - [x] maxItems
  - [ ] uniqueItems
  - [ ] prefixItems
  - [ ] contains
  - [ ] minContains
  - [ ] maxContains
- [x] type: object

  - [x] properties
  - [x] `additionalProperties: true`
  - [x] `additionalProperties: false`
  - [ ] `additionalProperties: { "type": "..." }`
  - [ ] patternProperties
  - [ ] propertyNames
  - [ ] dependentSchemas
  - [ ] dependentRequired
  - [ ] minProperties
  - [ ] maxProperties

- [x] anyOf
- [x] allOf
- [x] oneOf
- [ ] not
- [x] `$ref`
  - [x] key `#/defs/bar`
  - [x] index `#/defs/items/0/bar`
- [ ] if
- [x] const
- [x] `{ "type": ["string", "null"] }`

## TIPS

- Internal Conversion
  - `{ "type": ["string", "null"] }` -> `{ "oneOf": [ {"type": "string"}, {"type": "null"} ] }`
  - `"additionalProperties": true` -> `{ "additionalProperties": { "type": "any" } }`
  - `additionalProperties` requires `{ "type": ... }` like `JsonSchema::Object(additionalProperties=JsonSchema::string())`

## LICENSE

MIT
