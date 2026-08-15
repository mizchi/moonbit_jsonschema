struct MyStruct {
  nested: MyStruct_nested
  d1: MyStruct_d1
} derive(Eq, Debug, FromJson, ToJson)
struct MyStruct_nested {
  id: Int
} derive(Eq, Debug, FromJson, ToJson)
struct MyStruct_d1 {
  d2: MyStruct_d1_d2
} derive(Eq, Debug, FromJson, ToJson)
struct MyStruct_d1_d2 {
  d3: String
} derive(Eq, Debug, FromJson, ToJson)
