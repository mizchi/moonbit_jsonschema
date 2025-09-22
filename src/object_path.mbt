///|
enum ObjectPath {
  Root
  Key(ObjectPath, key~ : String)
  Index(ObjectPath, index~ : Int)
} derive(Eq)

///|
fn add_index(self : ObjectPath, index : Int) -> ObjectPath {
  Index(self, index~)
}

///|
fn add_key(self : ObjectPath, key : String) -> ObjectPath {
  Key(self, key~)
}

///|
pub impl Show for ObjectPath with output(self, logger) {
  match self {
    Root => logger.write_string("$")
    Key(p, key~) =>
      logger..write_object(p)..write_string(".")..write_string(key)
    Index(p, index~) =>
      logger
      ..write_object(p)
      ..write_string("[")
      ..write_object(index)
      ..write_string("]")
  }
}
