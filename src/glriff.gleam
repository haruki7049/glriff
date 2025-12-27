import gleam/option.{type Option}

pub type Chunk {
  Chunk(four_cc: BitArray, data: BitArray)
  ListChunk(chunks: List(Chunk))
  RiffChunk(chunk: Option(Chunk))
}
