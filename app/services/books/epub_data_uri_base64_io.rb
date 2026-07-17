# frozen_string_literal: true

module Books
  # Streams base64 payloads to IO without holding the full decoded blob in Ruby heap.
  module EpubDataUriBase64Io
    BASE64_CHUNK_CHARS = 131_072

    module_function

    def write_string(encoded, io)
      encoded = encoded.delete("\n\r")
      write_range(encoded, 0, encoded.length, io)
    end

    def write_range(source, start, finish, io)
      pos = start
      while pos < finish
        pos = write_chunk(source, pos, finish, io)
        break unless pos
      end
    end

    def write_chunk(source, pos, finish, io)
      chunk_end = chunk_end_for(source, pos, finish)
      return nil if chunk_end <= pos

      io.write(Base64.decode64(source[pos...chunk_end]))
      chunk_end
    end

    def chunk_end_for(_source, pos, finish)
      chunk_end = [pos + BASE64_CHUNK_CHARS, finish].min
      return chunk_end if chunk_end == finish

      align = (chunk_end - pos) % 4
      chunk_end -= align if align.positive?
      chunk_end
    end
  end
end
