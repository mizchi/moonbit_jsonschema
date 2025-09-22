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
  let validator = @jsonschema.Validator::compile(schema)
  match validator.validate(5) {
    Ok(_) => println("passed")
    Err(errors) => println("validation erros: \{errors}")
  }
}
```

## with $ref

```mbt
  let schema : Json = {
    "definitions": { "PositiveInteger": { "type": "integer", "minimum": 0 } },
    "$ref": "#/definitions/PositiveInteger",
  }
  let validator = Validator::compile(raw_schema)
  validator.validate(5)
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
- [ ] if
- [x] const
- [ ] `{ "type": ["string", "null"] }`
  - Convert to `{ "oneOf": [ {"type": "string"}, {"type": "null"} ] }`

## TIPS

- Internal Conversion
  - `{ "type": ["string", "null"] }` -> `{ "oneOf": [ {"type": "string"}, {"type": "null"} ] }`
  - `"additionalProperties": true` -> `{ "additionalProperties": { "type": "any" } }`
  - `additionalProperties` requires `{ "type": ... }` like `JsonSchema::Object(additionalProperties=JsonSchema::string())`
