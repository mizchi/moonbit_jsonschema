///|
priv suberror MyError

///|
priv suberror MyError1 String

///|
priv suberror MyError2 {
  A
  B(String)
}

///|
test "builtn failure" {
  // try catch is expression
  let v = fail("mes") catch { _ => 10 }
  assert_eq(v, 10)
  try {
    let s = 10
    if s > 0 {
      raise MyError1("my error")
    } else {
      ()
    }
  } catch {
    MyError1(msg) => assert_eq(msg, "my error")
  } noraise {
    _v => fail("unreachable")
  }
}

///|
test "try? transform raise to Result" {
  let f1 = fn(v : Int) -> Int raise MyError1 {
    if v > 0 {
      v * 2
    } else {
      raise MyError1("negative")
    }
  }
  // try? transform `T raise E` => `Result[T, E]`
  let r1 : Result[Int, MyError1] = try? f1(10)
  match r1 {
    Ok(v) => assert_eq(v, 20)
    Err(_) => fail("unreachable")
  }
  // assert_eq(r1.unwrap(), Ok(20))
}

///|
fn _will_fail() -> Unit raise MyError1 {
  raise MyError1("will fail")
}

///|
/// raise any error
fn _will_fail2() -> Unit raise {
  _will_fail()
  raise MyError
  raise MyError2::A
  raise MyError2::B("will fail2")
}

///|
/// manualy declared noraise
fn _noraise() -> Unit noraise {
  ()
}

///|
test "function error declaration" {
  _noraise()
  _will_fail() catch {
    MyError1(_) => ()
    // _ => fail("unreachable")
  }
  _will_fail2() catch {
    MyError1(_) => ()
    MyError2::B(_) => fail("should not reach here")
    _ => fail("unreachable")
  }
  let handler : () -> Unit raise = fn() raise { fail("fail") }
  try {
    handler()
    fail("unreachable")
  } catch {
    _ => assert_true(true)
  }
}
