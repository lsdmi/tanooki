# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ImageProcessorTest < ActiveSupport::TestCase
    setup do
      skip 'libvips is not available' unless Attachments::VariantProcessing.available?
      require 'vips'
      @dir = Dir.mktmpdir
    end

    teardown do
      FileUtils.remove_entry(@dir) if @dir
    end

    test 'keeps a small image byte for byte' do
      path = write_image('small.png', Vips::Image.black(300, 200).add(120).cast(:uchar))

      result = ImageProcessor.call(path)

      assert_equal %w[image/png png], [result.content_type, result.extension]
      assert_equal File.binread(path), result.binary
    end

    test 'turns a large image into WebP no longer than 1600 px on either edge' do
      path = write_image('large.jpg', noise(2400, 1200), Q: 95)

      result = ImageProcessor.call(path)

      assert_equal 'image/webp', result.content_type
      assert_equal [1600, 800], [result.width, result.height]
      assert_equal 'image/webp', Marcel::MimeType.for(StringIO.new(result.binary))
    end

    test 'keeps transparency when a large PNG is converted' do
      rgb = noise(1800, 900)
      path = write_image('alpha.png', rgb.bandjoin(Vips::Image.black(1800, 900).cast(:uchar)))

      result = ImageProcessor.call(path)

      assert_equal 4, Vips::Image.new_from_buffer(result.binary, '').bands
    end

    test 'always converts formats browsers may not show, even when small' do
      path = write_image('small.tif', Vips::Image.black(40, 40).add(50).cast(:uchar))

      assert_equal 'image/webp', ImageProcessor.call(path)&.content_type
    end

    test 'keeps an animated GIF even when it is large' do
      frames = Vips::Image.arrayjoin(Array.new(3) { noise(1800, 300) }, across: 1)
      frames = frames.mutate { |image| image.set_type!(GObject::GINT_TYPE, 'page-height', 300) }
      path = write_image('anim.gif', frames)

      result = ImageProcessor.call(path)

      assert_equal 'image/gif', result.content_type
      assert_equal File.binread(path), result.binary
    end

    test 'converts a large truncated image to nil instead of a half-grey picture' do
      source = write_image('whole_large.jpg', noise(2400, 1200))
      path = File.join(@dir, 'cut_large.jpg')
      File.binwrite(path, File.binread(source).byteslice(0, 20_000))

      assert_nil ImageProcessor.call(path)
    end

    test 'returns nil for a file that is not an image' do
      path = File.join(@dir, 'fake.png')
      File.write(path, 'definitely not an image')

      assert_nil ImageProcessor.call(path)
    end

    test 'returns nil for a truncated image' do
      source = write_image('whole.jpg', noise(800, 800))
      path = File.join(@dir, 'cut.jpg')
      File.binwrite(path, File.binread(source).byteslice(0, 2000))

      assert_nil ImageProcessor.call(path)
    end

    private

    def noise(width, height)
      red, green, blue = [128, 90, 60].map do |mean|
        Vips::Image.gaussnoise(width, height, mean:, sigma: 40).cast(:uchar)
      end
      red.bandjoin([green, blue])
    end

    def write_image(name, image, **)
      path = File.join(@dir, name)
      image.write_to_file(path, **)
      path
    end
  end
end
