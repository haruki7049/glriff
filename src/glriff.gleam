import gleam/bit_array
import gleam/bool
import gleam/list
import gleam/result

/// Represents a RIFF (Resource Interchange File Format) chunk.
///
/// RIFF is a binary file format that stores data in tagged chunks. This type
/// models the three types of chunks that can appear in RIFF files:
///
/// - `Chunk`: A basic chunk with a 4-byte FourCC identifier and binary data
/// - `ListChunk`: A LIST chunk containing a list of sub-chunks
/// - `RiffChunk`: A RIFF chunk (the root container) with a FourCC type identifier and sub-chunks
///
pub type Chunk {
  /// A basic RIFF chunk with a FourCC identifier and data payload.
  ///
  /// The `four_cc` field is a 4-byte identifier (e.g., "fmt ", "data").
  /// The `data` field contains the chunk's binary payload.
  Chunk(four_cc: BitArray, data: BitArray)
  
  /// A LIST chunk that contains multiple sub-chunks.
  ///
  /// LIST chunks are used to group related chunks together.
  ListChunk(chunks: List(Chunk))
  
  /// A RIFF chunk representing the root container of a RIFF file.
  ///
  /// The `four_cc` field specifies the file type (e.g., "WAVE" for WAV files).
  /// The `chunks` field contains all sub-chunks within this RIFF file.
  RiffChunk(four_cc: BitArray, chunks: List(Chunk))
}

/// Converts a RIFF chunk to its binary representation.
///
/// This function serializes a chunk into the RIFF binary format, which consists of:
/// - For basic Chunk: FourCC (4 bytes) + Size (4 bytes, little-endian) + Data
/// - For ListChunk: "LIST" (4 bytes) + Size (4 bytes) + Concatenated sub-chunks
/// - For RiffChunk: "RIFF" (4 bytes) + Size (4 bytes) + FourCC (4 bytes) + Concatenated sub-chunks
///
/// ## Examples
///
/// ```gleam
/// let chunk = Chunk(four_cc: <<"fmt ">>, data: <<"EXAMPLE_DATA">>)
/// let binary = to_bit_array(chunk)
/// // Returns: <<"fmt ", 12:size(32)-little, "EXAMPLE_DATA">>
/// ```
///
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

/// Represents errors that can occur when parsing a RIFF chunk from binary data.
///
pub type FromBitArrayError {
  /// Failed to create a list of chunks from the binary data.
  ///
  /// This error wraps a `ToChunkListError` that provides more detail about
  /// what went wrong during chunk list parsing.
  FailedToCreateChunkList(inner: ToChunkListError)
  
  /// The binary data does not conform to the RIFF format specification.
  ///
  /// This can occur when:
  /// - The data is too short to contain required headers
  /// - The chunk size doesn't match the actual data size
  /// - Required fields are missing or malformed
  InvalidFormat
}

/// Parses a RIFF chunk from binary data.
///
/// This function reads binary data in RIFF format and constructs the appropriate
/// `Chunk` variant based on the chunk identifier:
/// - "RIFF" → `RiffChunk`
/// - "LIST" → `ListChunk`
/// - Other FourCC → basic `Chunk`
///
/// The function validates that:
/// - The data contains at least 8 bytes (FourCC + size)
/// - The declared size matches the actual data size
/// - All sub-chunks (for RIFF and LIST) are valid
///
/// ## Examples
///
/// ```gleam
/// let binary = <<"fmt ", 12:size(32)-little, "EXAMPLE_DATA">>
/// case from_bit_array(binary) {
///   Ok(chunk) -> // Successfully parsed chunk
///   Error(InvalidFormat) -> // Invalid RIFF data
/// }
/// ```
///
pub fn from_bit_array(bits: BitArray) -> Result(Chunk, FromBitArrayError) {
  use id <- result.try(
    bit_array.slice(bits, 0, 4)
    |> result.replace_error(InvalidFormat),
  )

  use size_bits <- result.try(
    bit_array.slice(bits, 4, 4)
    |> result.replace_error(InvalidFormat),
  )

  let assert <<size:size(32)-little>> = size_bits

  case id {
    <<"RIFF">> -> {
      use four_cc <- result.try(
        bit_array.slice(bits, 8, 4)
        |> result.replace_error(InvalidFormat),
      )

      let last_index: Int = bit_array.byte_size(bits) - 12
      case last_index {
        0 -> Ok(RiffChunk(four_cc: four_cc, chunks: []))
        _ -> {
          use chunks <- result.try(
            to_chunk_list(bits, 12)
            |> result.map_error(FailedToCreateChunkList),
          )

          Ok(RiffChunk(four_cc: four_cc, chunks: chunks))
        }
      }
    }
    <<"LIST">> -> {
      let last_index: Int = bit_array.byte_size(bits) - 8
      case last_index {
        0 -> Ok(ListChunk(chunks: []))
        _ -> {
          use chunks <- result.try(
            to_chunk_list(bits, 8)
            |> result.map_error(FailedToCreateChunkList),
          )

          Ok(ListChunk(chunks: chunks))
        }
      }
    }
    _ -> {
      let last_index: Int = bit_array.byte_size(bits) - 8
      use data <- result.try(
        bit_array.slice(bits, 8, last_index)
        |> result.replace_error(InvalidFormat),
      )

      case size == bit_array.byte_size(data) {
        True -> Ok(Chunk(id, data))
        False -> Error(InvalidFormat)
      }
    }
  }
}

/// Represents errors that can occur when parsing a list of chunks from binary data.
///
pub type ToChunkListError {
  /// The chunk identifier (FourCC) could not be read from the expected position.
  InvalidId
  
  /// The chunk size field could not be read from the expected position.
  InvalidSize
  
  /// The chunk data could not be read from the expected position.
  InvalidData
  
  /// The declared chunk size does not match the actual available data.
  ///
  /// The `size` field contains the declared size from the chunk header.
  /// The `expected` field contains the actual size of the data that was read.
  SizeIsDifference(size: Int, expected: Int)
}

/// Recursively parses a list of chunks from binary data starting at a given position.
///
/// This internal helper function reads chunks sequentially from the binary data,
/// starting at the specified byte position. It continues until all data has been
/// consumed or an error occurs.
///
/// Each chunk consists of:
/// - 4 bytes: FourCC identifier
/// - 4 bytes: Size (little-endian integer)
/// - N bytes: Data (where N = size from previous field)
///
/// ## Parameters
///
/// - `bits`: The binary data containing RIFF chunks
/// - `position`: The byte offset to start reading from
///
/// ## Returns
///
/// Returns `Ok(chunks)` with a list of successfully parsed chunks, or
/// `Error(reason)` if parsing fails.
///
fn to_chunk_list(
  bits: BitArray,
  position: Int,
) -> Result(List(Chunk), ToChunkListError) {
  let total_size = bit_array.byte_size(bits)

  case position >= total_size {
    True -> Ok([])
    False -> {
      use id: BitArray <- result.try(
        bit_array.slice(bits, position, 4)
        |> result.replace_error(InvalidId),
      )

      use size_bits <- result.try(
        bit_array.slice(bits, position + 4, 4)
        |> result.replace_error(InvalidSize),
      )

      // Pattern match on the sliced bits for size
      let assert <<size:size(32)-little>> = size_bits

      use data <- result.try(
        bit_array.slice(bits, position + 8, size)
        |> result.replace_error(InvalidData),
      )

      use <- bool.guard(
        when: size != bit_array.byte_size(data),
        return: Error(SizeIsDifference(
          size: size,
          expected: bit_array.byte_size(data),
        )),
      )

      let next_position: Int = position + 8 + size
      let chunk: Chunk = Chunk(id, data)

      let rest_chunks: Result(List(Chunk), ToChunkListError) =
        to_chunk_list(bits, next_position)

      case rest_chunks {
        Ok(values) -> Ok([chunk, ..values])
        Error(err) -> Error(err)
      }
    }
  }
}
