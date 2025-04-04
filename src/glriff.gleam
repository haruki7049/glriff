import gleam/option.{type Option}

pub type RIFF {
  RIFF(header: BitArray, chunk: Option(List(Chunk)))
}

pub type Chunk {
  Chunk(id: BitArray, data: BitArray)
}
