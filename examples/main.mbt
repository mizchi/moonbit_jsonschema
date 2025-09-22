///|
async fn run_jsonschema(target : String) -> Unit {
  let str = @fs.read_file(target |> @encoding/utf8.encode)
    |> @encoding/utf8.decode
  let json = @json.parse(str)
  let schema : @jsonschema.Schema = @json.from_json(json)
  // let jsonr = @json.stringify(schema)
  println(schema.to_json())
  // @json.stringify(schema) |> println
  // let json = schema.to_string()
  // @json.stringify(schema) |> println
  let validator = @jsonschema.Validator::new(schema)
  let instance : Json = { "name": "Alice", "age": 30.0 }
  let result = validator.validate(instance)
  println(result)
  let passed = validator.validate(Json::string("hello"))
  println(passed)
  ()
}

///|
fn main {
  let arg = @env.args().get(1)
  guard arg is Some(path) else {
    println("Usage: main.mbt <path-to-jsonschema>")
    return
  }
  let fullpath = @env.current_dir().unwrap() + "/" + path
  println("Reading file: " + fullpath)
  @async.with_event_loop(fn(_root) { run_jsonschema(fullpath) }) catch {
    err => println(err.to_string())
  }
  ()
}
