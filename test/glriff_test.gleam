import gleam/bit_array
import gleam/option.{Some}
import gleeunit
import gleeunit/should
import glriff.{type Chunk, Chunk, ListChunk, RiffChunk}
import glriff/chunk

pub fn main() {
  gleeunit.main()
}

pub fn chunk_test() {
  Chunk(id: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
  |> chunk.to_bit_array()
  |> should.equal(
    [<<"fmt ">>, <<12:little>>, <<"EXAMPLE_DATA">>] |> bit_array.concat(),
  )
}

pub fn list_chunk_test() {
  let fmt_chunk: Chunk = Chunk(id: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
  let list_chunk: Chunk = ListChunk(chunks: [fmt_chunk, fmt_chunk])

  list_chunk
  |> chunk.to_bit_array()
  |> should.equal(
    [
      <<"LIST">>,
      <<34:little>>,
      <<"fmt ">>,
      <<12:little>>,
      <<"EXAMPLE_DATA">>,
      <<"fmt ">>,
      <<12:little>>,
      <<"EXAMPLE_DATA">>,
    ]
    |> bit_array.concat(),
  )
}

pub fn riff_chunk_test() {
  let fmt_chunk: Chunk = Chunk(id: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
  let riff_chunk: Chunk = RiffChunk(chunk: Some(fmt_chunk))

  riff_chunk
  |> chunk.to_bit_array()
  |> should.equal(
    [<<"RIFF">>, <<17>>, <<"fmt ">>, <<12>>, <<"EXAMPLE_DATA">>]
    |> bit_array.concat(),
  )
}
