///|
enum MbtSchema {
  String
  Number
  Boolean
  Null
  Object(properties~ : Map[String, MbtSchema])
  Array(items~ : MbtSchema)
} derive(Show)

///|
// suberror SchemaEncodeError String

///|
impl ToJson for MbtSchema with to_json(self) -> Json {
  // jsonvalue
  match self {
    MbtSchema::String => { "type": "string" }
    MbtSchema::Number => { "type": "number" }
    MbtSchema::Boolean => { "type": "boolean" }
    MbtSchema::Null => { "type": "null" }
    MbtSchema::Array(items~) => {
      println("Encoding Array with items: " + items.to_string())
      { "type": "array", "items": items.to_json() }
    }
    MbtSchema::Object(properties~) => {
      println("Encoding Object with properties: " + properties.to_string())
      let properties : Map[String, Json] = {}
      for k, v in properties {
        // let s: MbtSchema = @json.to
        properties.set(k, v.to_json())
      }
      { "type": "object", "properties": properties }
    }
    _ => { "type": "unknown" }
    // raise SchemaEncodeError("Not yet implemented:")
  }
}

///|
impl @json.FromJson for MbtSchema with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> MbtSchema raise {
  guard json is Json::Object(obj) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  // let type_value = obj.get("type").unwrap()
  match obj {
    { "type": String("string"), .. } => MbtSchema::String
    { "type": String("number"), .. } => MbtSchema::Number
    { "type": String("boolean"), .. } => MbtSchema::Boolean
    { "type": String("object"), "properties": Object(properties_json), .. } => {
      // let props_value = obj.get("properties")
      // guard properties_json is Array(items) else {
      //   raise @json.JsonDecodeError(
      //     (
      //       json_path.add_key("properties"),
      //       "Missing 'properties' field for object type",
      //     ),
      //   )
      // }
      let map : Map[String, MbtSchema] = {}
      for k, v in properties_json {
        map.set(k, MbtSchema::from_json(v, json_path.add_key(k)))
      }
      MbtSchema::Object(properties=map)
    }
    { "type": String("array"), .. } =>
      raise @json.JsonDecodeError(
        (json_path, "'array' type is not yet supported"),
      )
    // let items_value = obj.get("items")
    // guard items_value is Some(items_json) else {
    //   raise @error.new("Missing 'items' field for array type at " + json_path.to_string())
    // }
    // let item_schema = MbtSchema::from_json(items_json, json_path.child("items"))
    // MbtSchema::Array(item_schema)
    _ => raise @json.JsonDecodeError((json_path, "Unknown type: "))
  }
}

///|
async fn run_jsonschema(target : String) -> Unit {
  let str = @fs.read_file(target |> @encoding/utf8.encode)
    |> @encoding/utf8.decode
  let json = @json.parse(str)
  // println(str)
  // println(json)
  // let schema : MbtString = @json.from_json(json)
  // println("Schema type: " + schema.sType)
  // println(schema.to_json() |> Json::stringify)
  // 2
  // let s : MbtSchema = MbtSchema::String
  let parsed : MbtSchema = @json.from_json(json)
  println("Parsed schema: " + parsed.to_string())
  println("------")
  // let s : MbtSchema = MbtSchema::Object(properties={ "xxx": MbtSchema::String })
  println(parsed.to_json() |> Json::stringify)
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
