# Changelog

## 0.8.0

### Breaking Changes

- Remove `ToJson for JsonSchema` impl and all `to_json_schema` methods
  - `JsonSchema` can no longer be serialized back to JSON
  - `ArraySchema` and `ObjectSchema` no longer derive `ToJson`
- Remove `Builder::define_schema` and `Builder::emit_json_schema` (unimplemented stubs)
- Remove `Builder::internal_state` field (Builder is now stateless)

### Removed

- `JsonSchemaSerializable` trait (replaced by `FromJson` + direct methods)
- `with_type_property` helper function
- All `parse` stub implementations (`abort("not implemented")`)
- Round-trip serialization test in codegen

### Improvements

- Expand benchmarks: 1 -> 7 cases (object, nested, failure path, $ref, large array, oneOf, parse)
- Use `@bench.Bench::keep` instead of `ignore` for accurate benchmarks

## 0.7.0

### Project Modernization

- Migrate `moon.pkg.json` to `moon.pkg` format (new MoonBit convention)
- Replace `Makefile` with `justfile`
- Update CI workflow: lint/test split, matrix strategy, `just` commands
- Add `.pre-commit-config.yaml`, `CLAUDE.md`
- Remove `warn-list` / `alert-list` from `moon.mod.json`
- Add explicit core package imports (`moonbitlang/core/json`, `moonbitlang/core/bench`, `moonbitlang/core/test`)

### Code Fixes (Latest MoonBit Compatibility)

- Fix `@json.Null` / `@json.True` / `@json.False` -> `Null` / `True` / `False` (prelude migration)
- Fix `not(expr)` -> `!(expr)`
- Fix `fn method(self : Type)` -> `fn Type::method(self : Type)`
- Fix `typealias` -> `using @pkg {type T}`
- Fix `fn(...) {}` closures -> `(...) => {}`
- Fix `x..f()` chain endings
- Fix `@test.T` -> `@test.Test`
- Fix `.size()` -> `.length()`
- Replace `...` placeholders with `abort("not implemented")`
