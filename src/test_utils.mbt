///|
fn[T, E] assert_ok(x : Result[T, E]) -> Unit {
  guard x is Ok(_)
}

///|
fn[T, E] assert_err(x : Result[T, E]) -> Unit {
  guard x is Err(_)
}

///|
fn[T : Eq, E] expect_ok(x : Result[T, E], content? : T) -> T raise {
  if x is Ok(v) {
    if content is Some(content) {
      if v == content {
        return v
      } else {
        fail("Ok but content mismatch")
      }
    }
    return x.unwrap()
  }
  fail("Expected Ok, got Err")
}
