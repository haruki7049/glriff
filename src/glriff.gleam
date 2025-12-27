pub type Chunk {
  Chunk(four_cc: BitArray, data: BitArray)
  ListChunk(chunks: List(Chunk))
  RiffChunk(four_cc: BitArray, chunks: List(Chunk))
}
