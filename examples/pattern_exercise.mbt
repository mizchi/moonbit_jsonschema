// Test Helper

///|
test "array pattern match" {
  let items : Array[Int] = [1, 2, 3, 4]
  match items {
    [] | [0] => fail("unreachable")
    [42, ..] => fail("unreachable")
    [0, .. _rest] => fail("unreachable")
    // match here
    [1, .. intermediates, last] if intermediates == [2, 3] => assert_eq(last, 4)
    _ => fail("unreachable")
  }
}

///|
test "built-in Option and Result" {
  // String? = Option[T]
  let opt_str : String? = Some("hello")
  match opt_str {
    Some(v) => inspect(v, content="hello")
    None => fail("unreachable")
  }
  // unsafe but it works here
  let _ = opt_str.unwrap()
  let _ = opt_str.unwrap_or("default")
  let _ = opt_str.map_or("default", v => v + "_mod")
  let ret : Result[String, Int] = Err(404)
  match ret {
    Err(_) => assert_true(true)
    Ok(_) => fail("unreachable")
  }
  if ret is Ok(_) {
    // unsafe
    let _ = ret.unwrap()
    fail("unreachable")
  }
  // unsafe
  let _ = ret.unwrap_err()
  let _ = ret.unwrap_or("default")
  let _ = ret.map_err(e => e + 1)

}

///|
test "iter pattern match" {
  match 5 {
    100..<1000 => fail("unreachable")
    100..=1000 => fail("unreachable")
    0..=4 => fail("unreachable")
    0..=5 => assert_true(true)
    _ => fail("unreachable")
  }
}

///|
test "tuple pattern match" {
  let (a, (b, _) as tuple, _) as triple = (1, (true, 5), false)
  "a: \{a}, b: \{b}" |> assert_eq("a: 1, b: true")
  "tuple: \{tuple}" |> assert_eq("tuple: (true, 5)")
  "triple: \{triple}" |> assert_eq("triple: (1, (true, 5), false)")
}

///|
priv struct TestPoint {
  x : Int
  y : Int
}

///|
test "struct pattern match" {
  let p = Some(TestPoint::{ x: 10, y: 20 })
  match p {
    // match exact
    Some({ x: 10, y }) => assert_eq(y, 20)
    // x as v
    Some({ x: v, y: 20 }) => assert_eq(v, 10)
    // ignore rest
    _ => ()
  }
  match p {
    Some({ y, .. }) => assert_eq(y, 20)
    _ => ()
  }
  match p {
    Some(p) => assert_eq(p.x, 10)
    None => fail("unreachable")
  }
}

///|
struct TestPointTuple(Int, Int) derive(Eq)

///|
test "tuple struct pattern match" {
  let p = TestPointTuple(10, 20)
  match p {
    // positional
    TestPointTuple(10, y) => assert_eq(y, 20)
    TestPointTuple(x, 20) => assert_eq(x, 10)
    _ => fail("unreachable")
  }
}

///|
enum TestEnum {
  A
  B(Int)
  // T? => Option[T]
  C(String?)
  D(t~ : Int, u~ : Int)
} derive(Eq, Show)

///|
test "enum pattern match" {
  let v = TestEnum::B(42)
  let _v1 : TestEnum = A
  let _v2 : TestEnum = TestEnum::A
  match v {
    // TestEnum::A or A
    A => fail("unreachable")
    // positional pattern
    // match here
    B(x) => assert_eq(x, 42)
    C(None) => fail("unreachable")
    C(Some(_)) => fail("unreachable")
    D(u=1, ..) => fail("unreachable")
    // same name witch ~
    D(t~, ..) => ignore(t)
  }
  let xs : Array[TestEnum] = [
    // MyEnum::
    A,
    TestEnum::B(5),
    TestEnum::C(None),
    TestEnum::D(t=10, u=20),
  ]
  match xs {
    [TestEnum::A, TestEnum::B(v), TestEnum::C(None), TestEnum::D(t=10, u~)] => {
      assert_eq(v, 5)
      assert_eq(u, 20)
    }
    _ => inspect(xs, content="unreachable")
  }
}

///|
test "string pattern match" {
  match "hello" {
    [] => fail("unreachable")
    ['h', 'e', 'l', l, 'o'] => assert_eq(l, 'l')
    _ => fail("unreachable")
  }
  match 'c' {
    'a'..='b' => fail("unreachable")
    'c'..<'z' => assert_true(true)
    _ => fail("unreachable")
  }
}
