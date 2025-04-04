import gleam/option.{type Option}

pub type RIFF {
  RIFF(chunk: Option(Chunk))
}

pub type Chunk {
  Chunk(id: BitArray, data: BitArray)
  List(chunks: List(Chunk))
}
