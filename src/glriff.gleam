import gleam/option.{type Option, None, Some}

pub type RIFF {
  RIFF(header: BitArray, chunk: Option(Chunk))
}

pub type Chunk {
  List(id: BitArray, size: Int, list_type: BitArray, sub_chunks: List(Chunk))
  Chunk(id: BitArray, size: Int, data: BitArray)
}
