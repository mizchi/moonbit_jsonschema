///|
async fn run_jsonschema(target : String) -> Unit {
  let fpath : Bytes = target |> @encoding/utf8.encode
  let str = @fs.read_file(fpath) |> @encoding/utf8.decode
  let raw_json : Json = @json.parse(str)
  let validator = @jsonschema.Validator::from_json(raw_json)
  let instance : Json = 1
  let result = validator.validate(instance)
  println(result)
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
