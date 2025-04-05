import gleam/bit_array
import glriff.{type Chunk}

pub fn to_bit_array(chunk: Chunk) -> BitArray {
  let id: BitArray = chunk.id
  let data: BitArray = chunk.data
  let size: BitArray = <<bit_array.byte_size(chunk.data)>>

  bit_array.concat([id, size, data])
}
