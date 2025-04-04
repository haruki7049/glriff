import gleam/option.{None, Some}
import gleeunit
import glriff

pub fn main() {
  gleeunit.main()
}

pub fn glriff_test() {
  glriff.RIFF(header: <<"RIFF">>, chunk: None)

  glriff.RIFF(
    header: <<"RIFF">>,
    chunk: Some(
      glriff.Chunk(id: <<"fmt ">>, size: 1000, data: <<"EXAMPLE_DATA">>),
    ),
  )
}
