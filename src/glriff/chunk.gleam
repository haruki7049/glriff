import gleam/bit_array
import gleam/list
import gleam/option.{None, Some}
import glriff.{type Chunk, Chunk, ListChunk, RiffChunk}

pub fn to_bit_array(chunk: Chunk) -> BitArray {
  case chunk {
    Chunk(id, data) -> {
      let size: BitArray = <<bit_array.byte_size(data):size(32)-little>>

      [id, size, data] |> bit_array.concat()
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
    RiffChunk(chunk) -> {
      let id: BitArray = <<"RIFF">>
      let data: BitArray = case chunk {
        None -> <<0>>
        Some(c) ->
          c
          |> to_bit_array()
      }
      let size: BitArray = <<bit_array.byte_size(data):size(32)-little>>

      [id, size, data] |> bit_array.concat()
    }
  }
}

pub fn from_bit_array(bits: BitArray) -> Chunk {
  let assert Ok(id): Result(BitArray, Nil) = bit_array.slice(bits, 0, 4)
  let assert Ok(<<size:8, _rest:bits>>) = bit_array.slice(bits, 4, 4)

  case id {
    <<"RIFF">> -> {
      let last_index: Int = bit_array.byte_size(bits) - 8
      case last_index {
        0 -> RiffChunk(chunk: None)
        _ -> {
          let assert Ok(chunk_bits): Result(BitArray, Nil) = bit_array.slice(bits, 8, last_index)
          let chunk: Chunk = from_bit_array(chunk_bits)

          RiffChunk(chunk: Some(chunk))
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
      let assert Ok(id): Result(BitArray, Nil) = bit_array.slice(bits, position, 4)
      let assert Ok(<<size:size(32)-little>>) = bit_array.slice(bits, position + 4, 4)

      let assert Ok(data): Result(BitArray, Nil) = bit_array.slice(bits, position + 8, size)
      assert size == bit_array.byte_size(data)

      let next_position: Int = position + 8 + size
      let chunk: Chunk = Chunk(id, data)

      [chunk, ..to_chunk_list(bits, next_position)]
    }
  }
}
