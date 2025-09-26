///|
pub struct StringConstraint {
  minLength : Int?
  maxLength : Int?
  enum_ : Array[String]?
  // pattern : String?
  // format : String?
  // contentEncoding : String?
  // contentMediaType : String?
  // description : String?
} derive (
  Show,
  Eq,
  FromJson(fields(enum_(rename="enum"))),
  ToJson(fields(enum_(rename="enum"))),
)
