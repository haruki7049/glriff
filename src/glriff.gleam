import gleam/option.{type Option}

pub type Chunk {
  Chunk(id: BitArray, data: BitArray)
  ListChunk(chunks: List(Chunk))
  RiffChunk(chunk: Option(Chunk))
}
