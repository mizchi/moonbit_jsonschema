///|
test "ok" {
  enum X {
    A(foo~ : Map[String, String])
    B
  } derive(Show, ToJson)
  let x = X::A(foo={ "foo": "bar", "baz": "qux" })
  let r = match x {
    X::A(foo~) => {
      println("Matched A with map: " + foo.to_string())
      "A"
    }
    X::B => {
      println("Matched B")
      "B"
    }
  }
  println("Result: " + r)
  println(x.to_string())
  println(x.to_json() |> Json::stringify)
  ()
}
