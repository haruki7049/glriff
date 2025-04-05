import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import glriff
import glriff/chunk

pub fn main() {
  gleeunit.main()
}

pub fn glriff_test() {
  glriff.RIFF(chunk: None)

  glriff.RIFF(
    chunk: Some(glriff.Chunk(id: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)),
  )
}

pub fn chunk_test() {
  glriff.Chunk(id: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
  |> chunk.to_bit_array()
  |> should.equal(<<>>)
}
