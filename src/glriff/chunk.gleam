import gleam/bit_array
import gleam/list
import glriff.{type Chunk, Chunk, ListChunk, RiffChunk}

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

pub fn from_bit_array(bits: BitArray) -> Chunk {
  let assert Ok(id): Result(BitArray, Nil) = bit_array.slice(bits, 0, 4)
  let assert Ok(<<size:size(32)-little>>) = bit_array.slice(bits, 4, 4)

  case id {
    <<"RIFF">> -> {
      let assert Ok(four_cc): Result(BitArray, Nil) =
        bit_array.slice(bits, 8, 4)

      let last_index: Int = bit_array.byte_size(bits) - 12
      case last_index {
        0 -> RiffChunk(four_cc: four_cc, chunks: [])
        _ -> {
          let chunks: List(Chunk) = to_chunk_list(bits, 12)
          RiffChunk(four_cc: four_cc, chunks: chunks)
        }
      }
    }
    <<"LIST">> -> {
      let last_index: Int = bit_array.byte_size(bits) - 8
      case last_index {
        0 -> ListChunk(chunks: [])
        _ -> {
          let chunks: List(Chunk) = to_chunk_list(bits, 8)
          ListChunk(chunks: chunks)
        }
      }
    }
    _ -> {
      let last_index: Int = bit_array.byte_size(bits) - 8
      let assert Ok(data) = bit_array.slice(bits, 8, last_index)

      assert size == bit_array.byte_size(data)

      Chunk(id, data)
    }
  }
}

fn to_chunk_list(bits: BitArray, position: Int) -> List(Chunk) {
  let total_size = bit_array.byte_size(bits)

  case position >= total_size {
    True -> []
    False -> {
      let assert Ok(id): Result(BitArray, Nil) =
        bit_array.slice(bits, position, 4)
      let assert Ok(<<size:size(32)-little>>) =
        bit_array.slice(bits, position + 4, 4)

      let assert Ok(data): Result(BitArray, Nil) =
        bit_array.slice(bits, position + 8, size)
      assert size == bit_array.byte_size(data)

      let next_position: Int = position + 8 + size
      let chunk: Chunk = Chunk(id, data)

      [chunk, ..to_chunk_list(bits, next_position)]
    }
  }
}
