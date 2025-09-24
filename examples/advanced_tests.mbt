///|
/// Snapshot test that records anything written to `t`
/// will be saved to `__snapshots__/<filename>`
test "record anything" (t : @test.T) {
  t.write("Hello, world!")
  t.writeln(" And hello, MoonBit!")
  t.snapshot(filename="record_anything.txt")
}

///|
struct TestPointWithArbitrary {
  x : Int
  y : Int
} derive(Show, Eq, Arbitrary)

///|
/// run with `moon bench`
test (b : @bench.T) {
  let seed = @quickcheck/splitmix.new()
  b.bench(count=20, fn() {
    let _p = TestPointWithArbitrary::arbitrary(100, seed)

  })
}
