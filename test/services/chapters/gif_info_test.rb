# frozen_string_literal: true

require 'test_helper'

module Chapters
  class GifInfoTest < ActiveSupport::TestCase
    test 'counts frames and delay without decoding pixels' do
      info = GifInfo.call(write_gif(10, 20))

      assert_equal 2, info.frames
      assert_equal 300, info.duration_ms
      assert_predicate info, :animated?
    end

    test 'ignores a file that is not a gif' do
      path = Tempfile.new('still').path
      File.binwrite(path, 'not a gif')

      assert_nil GifInfo.call(path)
    end

    test 'a gif preview reports the motion and returns one still' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(File.binread(write_gif(10, 20))), filename: 'motion.gif', content_type: 'image/gif',
        service_name: 'test_chapter_images', identify: false
      )
      preview = ImageView.call(blob)

      assert_predicate preview, :animated
      assert_equal 2, preview.frames
      assert_predicate preview.binary, :present?
    end

    private

    def write_gif(*delays)
      bytes = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 1, 0, 1, 0, 0, 0, 0]
      delays.each { |delay| bytes.concat(frame(delay)) }
      bytes << 0x3B
      @gif = Tempfile.new(['motion', '.gif'])
      @gif.binmode
      @gif.write(bytes.pack('C*'))
      @gif.flush
      @gif.path
    end

    def frame(delay)
      [0x21, 0xF9, 0x04, 0x00, delay & 0xFF, (delay >> 8) & 0xFF, 0x00, 0x00,
       0x2C, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0x02, 0x02, 0x4C, 0x01, 0x00]
    end
  end
end
