# @mizchi/jsonschema

```
$ moon add mizchi/jsonschema
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
  - [x] prefixItems
  - [ ] additionalItems
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
