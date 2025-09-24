///|
test "test with assert" {
  assert_eq(1 + 1, 2)
  assert_not_eq(1 + 1, 3)
  assert_true(true)
  assert_false(false)
  // with pipe
  true |> assert_true
  if false {
    fail("test raise")
  }
  let v : Result[Int, Unit] = Ok(42)
  // moon test -u update content="..."
  inspect(v, content="Ok(42)")
  42 |> Some |> inspect(content="Some(42)")
}

///|
test "basics" {
  let x : Int = 42
  // infer with String
  let y = "str"
  let mut v = 0
  v += 1
  assert_eq(x, 42)
  ignore((x, y, v))
  let inc : (Int) -> Int = fn(a) { a + 1 }
  // or
  let _ = fn(a : Int) -> Int { a + 1 }
  assert_eq(inc(1), 2)

  // string interpolation
  let name = "world"
  let greeting = "Hello, \{name}!"
  assert_eq(greeting, "Hello, world!")
  let _multiline =
    #|This is a
    #|multiline string.

}

///|
test "if/match" {
  let x : Int? = Some(10)
  let y = if x is Some(42) { 0 } else if x is Some(v) { v * 2 } else { 0 }
  assert_eq(y, 20)
  let z = match x {
    Some(42) => 0
    // match here
    Some(v) => v * 2
    None => 0
  }
  assert_eq(z, 20)
  // _ match all
  let _ = match x {
    Some(42) => 0
    // match here
    _ => 0
  }

  // ignore value
  let _ = match Some(10) {
    Some(_) => 1
    None => 2
  }
  42 |> ignore
}

///|
test "guard condition" {
  let x : Int? = 10 |> Some
  guard x is Some(v) else {
    // can not access v here
    fail("unreachable")
  }
  // can access matched `v` here
  assert_eq(v, 10)
}

///|
test "for" {
  let arr : Array[Int] = [1, 2, 3]
  for v in arr {
    assert_true(v > 0)
  }
  for idk, v in arr {
    ignore(idk)
    assert_true(v > 0)
  }
  // range operator now supports only in for loop
  for i in 0..=3 {
    assert_true(i >= 0 && i < 4)
  }
  let map : Map[String, Int] = { "a": 1, "b": 2 }
  for k, v in map {
    assert_true(v > 0)
    assert_true(k == "a" || k == "b")
  }
}

///|
test "built-in types" {
  let _b : Bool = true
  let _i : Int = 42
  let _u : UInt = 42
  let _f : Float = 3.14
  let _s : String = "hello"
  let _c : Char = 'a'
  let _bytes : Bytes = b"byte"
  let _map : Map[String, Int] = { "a": 1, "b": 2 }
  let _arr : Array[Int] = [1, 2, 3]
  let _set : Set[Int] = Set::new()
  let _set_from_array = Set::from_array([1, 2, 3])
  let _fixed : FixedArray[Int] = [1, 2, 3]
  let _iter : Iter[Int] = [1, 2, 3].iter()
  let _result1 : Result[Int, String] = Ok(42)
  let _result2 : Result[Int, String] = Err("error")
  let _opt1 : Int? = Some(42)
  let _opt2 : Int? = None
  let _tuple = (1, "str", 3.14)
  // with type hint
  let _tuple2 : (Int, String, Float) = (1, "str", 3.14)

}

///|
/// immutable List
fn[A] count(list : @list.List[A]) -> UInt {
  match list {
    Empty => 0
    More(_, tail~) => count(tail) + 1
  }
}

///|
test "advanced immutable types" {
  let empty = @list.empty()
  let xs = @list.cons(1, empty)
  let _ = xs.prepend(2)
  let _ = empty.prepend(3)
  let reversed_1 = xs.rev()
  count(reversed_1) |> assert_eq(1)

  // Advanced immutable
  let _immut_map : @immut/hashmap.HashMap[String, Int] = @immut/hashmap.from_array([
      ("a", 1),
      ("b", 2),
    ],
  )
  let _immut_set : @immut/array.T[Int] = @immut/array.from_array([1, 2, 3])

}

///|
fn add(a : Int, b : Int) -> Int {
  a + b
}

///|
/// generic fn example
fn[T, U] tap(value : T, f : (T) -> U) -> U {
  f(value)
}

///|
/// paramed fn example
fn pf0(a~ : Int, b~ : Int) -> Int {
  let _ : Int = a
  let _ : Int = b
  a + b
}

///|
/// positional and optional args fn example
fn pf1(a : Int, b? : Int = 1, c? : Int) -> Int {
  let _ : Int = a
  // default is unwrapped
  let _ : Int = b
  let _ : Int? = c
  a + b + c.unwrap_or(0)
}

///|
test "fn with pipe and partial args" {
  assert_eq(add(1, 2), 3)
  // with pipe
  1 |> add(2) |> assert_eq(3)
  42 |> tap(fn(v) { v + 1 }) |> assert_eq(43)
  pf0(a=1, b=2) |> assert_eq(3)
  pf0(b=2, a=1) |> assert_eq(3)
  pf1(1) |> assert_eq(2)
  pf1(1, b=2) |> assert_eq(3)
  pf1(1, b=2, c=3) |> assert_eq(6)
  // pipe with partial
  pf1(1) |> pf1(c=3) |> assert_eq(6)
}

///|
priv struct Point {
  x : Int
  y : Int
} derive(Show, Eq)

///|
test "struct" {
  let p = Point::{ x: 10, y: 20 }
  // require Eq trait
  assert_eq(p, Point::{ x: 10, y: 20 })
  // require Show trait
  inspect(p, content="{x: 10, y: 20}")
}

///|
priv struct Counter {
  mut counter : Int
}

///|
fn Counter::new() -> Self {
  { counter: 0 }
}

///|
fn Counter::value(self : Counter) -> Int {
  self.counter
}

///|
fn incement(self : Counter) -> Unit {
  self.counter += 1
}

///|
fn decrement(self : Counter) -> Unit {
  self.counter -= 1
}

///|
test "struct with mut" {
  let c = Counter::new()
  // Unit fn can chain with ..f()
  c..incement()..incement()..decrement()
  assert_eq(c.value(), 1)
}
