# frozen_string_literal: true

module Chapters
  # Reads frame count and delay from a GIF header. It does not decode pixels.
  class GifInfo
    Result = Data.define(:frames, :duration_ms) do
      def animated? = frames > 1
    end

    def self.call(path)
      File.open(path, 'rb') { |io| new(io).call }
    end

    def initialize(io)
      @io = io
    end

    def call
      return unless gif?

      packed = screen_packed
      return unless packed

      skip(table_bytes(packed))
      frames, centiseconds = walk
      Result.new(frames:, duration_ms: centiseconds * 10)
    end

    private

    def gif?
      @io.read(6)&.match?(/\AGIF8[79]a\z/)
    end

    def screen_packed
      @io.read(7)&.bytes&.last
    end

    def walk
      frames = 0
      centiseconds = 0
      while (kind = next_kind)
        frames, centiseconds = apply(kind, frames, centiseconds)
      end
      [frames, centiseconds]
    end

    def next_kind
      case read_byte
      when 0x21 then :extension
      when 0x2C then :image
      end
    end

    def apply(kind, frames, centiseconds)
      return [frames + (skip_image? ? 1 : 0), centiseconds] if kind == :image

      [frames, centiseconds + extension]
    end

    def extension
      return graphic_delay if read_byte == 0xF9

      skip_blocks
      0
    end

    def graphic_delay
      data = @io.read(read_byte.to_i).to_s
      skip_blocks
      data.bytesize >= 4 ? data.getbyte(1) | (data.getbyte(2) << 8) : 0
    end

    def skip_image?
      packed = @io.read(9)&.bytes&.last
      return false unless packed

      skip(table_bytes(packed))
      read_byte
      skip_blocks
      true
    end

    def table_bytes(packed)
      return 0 unless packed.anybits?(0x80)

      3 * (1 << ((packed & 0x07) + 1))
    end

    def skip_blocks
      size = read_byte
      while size&.positive?
        skip(size)
        size = read_byte
      end
    end

    def read_byte
      @io.read(1)&.ord
    end

    def skip(count)
      @io.seek(count, IO::SEEK_CUR) if count.to_i.positive?
    end
  end
end
