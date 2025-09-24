// struct B {
//   b: A
// } derive(Show, FromJson, ToJson)

// // #/definitions/V
// struct V(Double) derive(Show, FromJson, ToJson)

// // skip by compile error #/definitions/V

// // #/definitions/A
// struct A {
//   a: V
// } derive(Show, FromJson, ToJson)
