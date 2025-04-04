import gleam/option.{None, Some}
import gleeunit
import glriff

pub fn main() {
  gleeunit.main()
}

pub fn glriff_test() {
  glriff.RIFF(chunk: None)

  glriff.RIFF(
    chunk: Some(
      glriff.List([glriff.Chunk(id: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)]),
    ),
  )
}
