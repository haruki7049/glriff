import gleam/bit_array
import gleam/bool
import gleam/list
import gleam/result

pub type Chunk {
  Chunk(four_cc: BitArray, data: BitArray)
  ListChunk(chunks: List(Chunk))
  RiffChunk(four_cc: BitArray, chunks: List(Chunk))
}

pub fn to_bit_array(chunk: Chunk) -> BitArray {
  case chunk {
    Chunk(four_cc, data) -> {
      let size: BitArray = <<bit_array.byte_size(data):size(32)-little>>

      [four_cc, size, data] |> bit_array.concat()
    }
    ListChunk(chunk_list) -> {
      let id: BitArray = <<"LIST">>
      let data: BitArray =
        chunk_list
        |> list.map(fn(v) { v |> to_bit_array() })
        |> bit_array.concat()
      let size: BitArray = <<bit_array.byte_size(data):size(32)-little>>

      [id, size, data] |> bit_array.concat()
    }
    RiffChunk(four_cc, chunk_list) -> {
      let riff_header: BitArray = <<"RIFF">>
      let data: BitArray =
        chunk_list
        |> list.map(fn(v) { v |> to_bit_array() })
        |> bit_array.concat()
      let size: BitArray = <<bit_array.byte_size(data):size(32)-little>>

      [riff_header, size, four_cc, data] |> bit_array.concat()
    }
  }
}

pub type FromBitArrayError {
  FailedToCreateChunkList(inner: ToChunkListError)
  InvalidFormat
}

pub fn from_bit_array(bits: BitArray) -> Result(Chunk, FromBitArrayError) {
  use id <- result.try(
    bit_array.slice(bits, 0, 4)
    |> result.replace_error(InvalidFormat),
  )

  use size_bits <- result.try(
    bit_array.slice(bits, 4, 4)
    |> result.replace_error(InvalidFormat),
  )

  let assert <<size:size(32)-little>> = size_bits

  case id {
    <<"RIFF">> -> {
      use four_cc <- result.try(
        bit_array.slice(bits, 8, 4)
        |> result.replace_error(InvalidFormat),
      )

      let last_index: Int = bit_array.byte_size(bits) - 12
      case last_index {
        0 -> Ok(RiffChunk(four_cc: four_cc, chunks: []))
        _ -> {
          use chunks <- result.try(
            to_chunk_list(bits, 12)
            |> result.map_error(FailedToCreateChunkList),
          )

          Ok(RiffChunk(four_cc: four_cc, chunks: chunks))
        }
      }
    }
    <<"LIST">> -> {
      let last_index: Int = bit_array.byte_size(bits) - 8
      case last_index {
        0 -> Ok(ListChunk(chunks: []))
        _ -> {
          use chunks <- result.try(
            to_chunk_list(bits, 8)
            |> result.map_error(FailedToCreateChunkList),
          )

          Ok(ListChunk(chunks: chunks))
        }
      }
    }
    _ -> {
      let last_index: Int = bit_array.byte_size(bits) - 8
      use data <- result.try(
        bit_array.slice(bits, 8, last_index)
        |> result.replace_error(InvalidFormat),
      )

      case size == bit_array.byte_size(data) {
        True -> Ok(Chunk(id, data))
        False -> Error(InvalidFormat)
      }
    }
  }
}

pub type ToChunkListError {
  InvalidId
  InvalidSize
  InvalidData
  SizeIsDifference(size: Int, expected: Int)
}

fn to_chunk_list(
  bits: BitArray,
  position: Int,
) -> Result(List(Chunk), ToChunkListError) {
  let total_size = bit_array.byte_size(bits)

  case position >= total_size {
    True -> Ok([])
    False -> {
      use id: BitArray <- result.try(
        bit_array.slice(bits, position, 4)
        |> result.replace_error(InvalidId),
      )

      use size_bits <- result.try(
        bit_array.slice(bits, position + 4, 4)
        |> result.replace_error(InvalidSize),
      )

      // Pattern match on the sliced bits for size
      let assert <<size:size(32)-little>> = size_bits

      use data <- result.try(
        bit_array.slice(bits, position + 8, size)
        |> result.replace_error(InvalidData),
      )

      use <- bool.guard(
        when: size != bit_array.byte_size(data),
        return: Error(SizeIsDifference(
          size: size,
          expected: bit_array.byte_size(data),
        )),
      )

      let next_position: Int = position + 8 + size
      let chunk: Chunk = Chunk(id, data)

      let rest_chunks: Result(List(Chunk), ToChunkListError) =
        to_chunk_list(bits, next_position)

      case rest_chunks {
        Ok(values) -> Ok([chunk, ..values])
        Error(err) -> Error(err)
      }
    }
  }
}
