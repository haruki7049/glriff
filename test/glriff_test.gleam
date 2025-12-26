import gleam/bit_array
import gleam/option.{Some}
import gleeunit
import gleeunit/should
import glriff.{type Chunk, Chunk, ListChunk, RiffChunk}
import glriff/chunk
import simplifile

pub fn main() {
  gleeunit.main()
}

pub fn chunk_to_bit_array_test() {
  Chunk(id: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
  |> chunk.to_bit_array()
  |> should.equal(
    [<<"fmt ">>, <<12:size(32)-little>>, <<"EXAMPLE_DATA">>]
    |> bit_array.concat(),
  )
}

pub fn list_chunk_to_bit_array_test() {
  let fmt_chunk: Chunk = Chunk(id: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
  let list_chunk: Chunk = ListChunk(chunks: [fmt_chunk, fmt_chunk])

  list_chunk
  |> chunk.to_bit_array()
  |> should.equal(
    [
      <<"LIST">>,
      <<40:size(32)-little>>,
      <<"fmt ">>,
      <<12:size(32)-little>>,
      <<"EXAMPLE_DATA">>,
      <<"fmt ">>,
      <<12:size(32)-little>>,
      <<"EXAMPLE_DATA">>,
    ]
    |> bit_array.concat(),
  )
}

pub fn riff_chunk_to_bit_array_test() {
  let fmt_chunk: Chunk = Chunk(id: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
  let riff_chunk: Chunk = RiffChunk(chunk: Some(fmt_chunk))

  riff_chunk
  |> chunk.to_bit_array()
  |> should.equal(
    [
      <<"RIFF">>,
      <<20:size(32)-little>>,
      <<"fmt ">>,
      <<12:size(32)-little>>,
      <<"EXAMPLE_DATA">>,
    ]
    |> bit_array.concat(),
  )
}

pub fn read_chunk_test() {
  let assert Ok(fmt_chunk): Result(BitArray, simplifile.FileError) =
    simplifile.read_bits(from: "test/assets/fmt_chunk.riff")
  fmt_chunk
  |> should.equal(
    [<<"fmt ">>, <<12:size(32)-little>>, <<"EXAMPLE_DATA">>]
    |> bit_array.concat(),
  )
}

pub fn read_list_chunk_test() {
  let assert Ok(list_chunk): Result(BitArray, simplifile.FileError) =
    simplifile.read_bits(from: "test/assets/list_chunk.riff")
  list_chunk
  |> should.equal(
    [
      <<"LIST">>,
      <<40:size(32)-little>>,
      <<"fmt ">>,
      <<12:size(32)-little>>,
      <<"EXAMPLE_DATA">>,
      <<"fmt ">>,
      <<12:size(32)-little>>,
      <<"EXAMPLE_DATA">>,
    ]
    |> bit_array.concat(),
  )
}

pub fn read_riff_chunk_test() {
  let assert Ok(riff_chunk): Result(BitArray, simplifile.FileError) =
    simplifile.read_bits(from: "test/assets/riff_chunk_with_fmt_chunk.riff")

  riff_chunk
  |> should.equal(
    [
      <<"RIFF">>,
      <<20:size(32)-little>>,
      <<"fmt ">>,
      <<12:size(32)-little>>,
      <<"EXAMPLE_DATA">>,
    ]
    |> bit_array.concat(),
  )
}

fn read_wavefile_test() {
  let assert Ok(wavefile): Result(BitArray, simplifile.FileError) =
    simplifile.read_bits(from: "test/assets/test_data.wav")

  wavefile
  |> should.equal(
    [
      <<"RIFF">>,
      <<56:size(32)-little>>,
      <<"WAVE">>,
      <<"fmt ">>,
      <<16:size(32)-little>>,
      <<
        1,
        0,
        1,
        0,
        68,
        172,
        0,
        0,
        136,
        88,
        1,
        0,
        2,
        0,
        16,
        0,
        100,
        97,
        116,
        97,
        20,
        0,
        0,
        0,
        0,
        0,
        54,
        3,
        101,
        6,
        149,
        9,
        178,
        12,
        204,
        15,
        204,
        18,
        195,
        21,
        156,
        24,
        98,
        27,
      >>,
    ]
    |> bit_array.concat(),
  )
}
