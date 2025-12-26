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
