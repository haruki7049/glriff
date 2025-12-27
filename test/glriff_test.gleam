import gleam/result
import gleam/bit_array
import gleeunit
import gleeunit/should
import glriff.{type Chunk, Chunk, ListChunk, RiffChunk}
import simplifile

const error_chunk: Chunk = Chunk(four_cc: <<"ERR ">>, data: <<"THIS_IS_ERR_DATA">>)

pub fn main() {
  gleeunit.main()
}

pub fn chunk_from_bit_array_test() {
  let fmt_chunk: BitArray =
    [<<"fmt ">>, <<12:size(32)-little>>, <<"EXAMPLE_DATA">>]
    |> bit_array.concat()

  let expected: Chunk = Chunk(four_cc: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)

  fmt_chunk
  |> glriff.from_bit_array()
  |> result.unwrap(error_chunk)
  |> should.equal(expected)
}

pub fn list_chunk_from_bit_array_test() {
  let list_chunk: BitArray =
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
    |> bit_array.concat()

  let expected: Chunk =
    ListChunk([
      Chunk(<<"fmt ">>, <<"EXAMPLE_DATA">>),
      Chunk(<<"fmt ">>, <<"EXAMPLE_DATA">>),
    ])

  list_chunk
  |> glriff.from_bit_array()
  |> result.unwrap(error_chunk)
  |> should.equal(expected)
}

pub fn riff_chunk_from_bit_array_test() {
  let riff_chunk: BitArray =
    [
      <<"RIFF">>,
      <<20:size(32)-little>>,
      <<"TEST">>,
      <<"fmt ">>,
      <<12:size(32)-little>>,
      <<"EXAMPLE_DATA">>,
    ]
    |> bit_array.concat()

  let expected: Chunk =
    RiffChunk(four_cc: <<"TEST">>, chunks: [
      Chunk(<<"fmt ">>, <<"EXAMPLE_DATA">>),
    ])

  riff_chunk
  |> glriff.from_bit_array()
  |> result.unwrap(error_chunk)
  |> should.equal(expected)
}

pub fn chunk_to_bit_array_test() {
  Chunk(four_cc: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
  |> glriff.to_bit_array()
  |> should.equal(
    [<<"fmt ">>, <<12:size(32)-little>>, <<"EXAMPLE_DATA">>]
    |> bit_array.concat(),
  )
}

pub fn list_chunk_to_bit_array_test() {
  let fmt_chunk: Chunk = Chunk(four_cc: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
  let list_chunk: Chunk = ListChunk(chunks: [fmt_chunk, fmt_chunk])

  list_chunk
  |> glriff.to_bit_array()
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
  let fmt_chunk: Chunk = Chunk(four_cc: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
  let riff_chunk: Chunk = RiffChunk(four_cc: <<"TEST">>, chunks: [fmt_chunk])

  riff_chunk
  |> glriff.to_bit_array()
  |> should.equal(
    [
      <<"RIFF">>,
      <<20:size(32)-little>>,
      <<"TEST">>,
      <<"fmt ">>,
      <<12:size(32)-little>>,
      <<"EXAMPLE_DATA">>,
    ]
    |> bit_array.concat(),
  )
}

/// To check whether the binary expression on my tests is exact or not.
/// This test doesn't use glriff.
pub fn read_chunk_test() {
  let assert Ok(fmt_chunk): Result(BitArray, simplifile.FileError) =
    simplifile.read_bits(from: "test/assets/fmt_chunk.riff")
  let expected: Chunk = Chunk(four_cc: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)

  fmt_chunk
  |> glriff.from_bit_array()
  |> result.unwrap(error_chunk)
  |> should.equal(expected)
}

/// To check whether the binary expression on my tests is exact or not.
/// This test doesn't use glriff.
pub fn read_list_chunk_test() {
  let assert Ok(list_chunk): Result(BitArray, simplifile.FileError) =
    simplifile.read_bits(from: "test/assets/list_chunk.riff")
  let fmt_chunk: Chunk = Chunk(four_cc: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
  let expected: Chunk = ListChunk(chunks: [fmt_chunk, fmt_chunk])

  list_chunk
  |> glriff.from_bit_array()
  |> result.unwrap(error_chunk)
  |> should.equal(expected)
}

/// To check whether the binary expression on my tests is exact or not.
/// This test doesn't use glriff.
pub fn read_riff_chunk_test() {
  let assert Ok(riff_chunk): Result(BitArray, simplifile.FileError) =
    simplifile.read_bits(from: "test/assets/riff_chunk_with_fmt_chunk.riff")
  let fmt_chunk: Chunk = Chunk(four_cc: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
  let expected: Chunk = RiffChunk(four_cc: <<"TEST">>, chunks: [fmt_chunk])

  riff_chunk
  |> glriff.from_bit_array()
  |> result.unwrap(error_chunk)
  |> should.equal(expected)
}

pub fn read_wavefile_test() {
  let assert Ok(wavefile): Result(BitArray, simplifile.FileError) =
    simplifile.read_bits(from: "test/assets/test_data.wav")
  let fmt_chunk: Chunk =
    Chunk(four_cc: <<"fmt ">>, data: <<
      1, 0, 1, 0, 68, 172, 0, 0, 136, 88, 1, 0, 2, 0, 16, 0,
    >>)
  let data_chunk: Chunk =
    Chunk(four_cc: <<"data">>, data: <<
      0, 0, 54, 3, 101, 6, 149, 9, 178, 12, 204, 15, 204, 18, 195, 21, 156, 24,
      98, 27,
    >>)
  let expected: Chunk =
    RiffChunk(four_cc: <<"WAVE">>, chunks: [fmt_chunk, data_chunk])

  wavefile
  |> glriff.from_bit_array()
  |> result.unwrap(error_chunk)
  |> should.equal(expected)
}
