# frozen_string_literal: true

require 'test_helper'

class CoverImageValidatorTest < ActiveSupport::TestCase
  CoverFile = Data.define(:content_type, :tempfile, :size)

  test 'valid when file is blank' do
    validator = CoverImageValidator.new(nil)

    assert_predicate validator, :valid?
    assert_empty validator.errors
  end

  test 'valid for webp at minimum dimensions and 3:4 aspect' do
    Tempfile.create(['cover', '.webp']) do |tmp|
      file = cover_file(content_type: 'image/webp', tempfile: tmp, size: 500.kilobytes)
      FastImage.stub(:size, [600, 800]) do
        validator = CoverImageValidator.new(file)

        assert_predicate validator, :valid?
        assert_empty validator.errors
      end
    end
  end

  test 'valid for avif within aspect tolerance' do
    Tempfile.create(['cover', '.avif']) do |tmp|
      file = cover_file(content_type: 'image/avif', tempfile: tmp, size: 900.kilobytes)
      FastImage.stub(:size, [800, 1067]) do
        validator = CoverImageValidator.new(file)

        assert_predicate validator, :valid?
        assert_empty validator.errors
      end
    end
  end

  test 'invalid when not webp or avif' do
    Tempfile.create(['cover', '.png']) do |tmp|
      file = cover_file(content_type: 'image/png', tempfile: tmp, size: 100.kilobytes)
      FastImage.stub(:size, [600, 800]) do
        validator = CoverImageValidator.new(file)

        assert_not validator.valid?
        assert_includes validator.errors, 'Обкладинка має бути у форматі WebP або AVIF.'
      end
    end
  end

  test 'invalid when width is below minimum' do
    Tempfile.create(['cover', '.webp']) do |tmp|
      file = cover_file(content_type: 'image/webp', tempfile: tmp, size: 100.kilobytes)
      FastImage.stub(:size, [599, 800]) do
        validator = CoverImageValidator.new(file)

        assert_not validator.valid?
        assert_includes validator.errors, 'Ширина обкладинки має бути не менше 600px.'
      end
    end
  end

  test 'invalid when height is below minimum' do
    Tempfile.create(['cover', '.webp']) do |tmp|
      file = cover_file(content_type: 'image/webp', tempfile: tmp, size: 100.kilobytes)
      FastImage.stub(:size, [600, 799]) do
        validator = CoverImageValidator.new(file)

        assert_not validator.valid?
        assert_includes validator.errors, 'Висота обкладинки має бути не менше 800px.'
      end
    end
  end

  test 'invalid when aspect ratio is outside tolerance' do
    Tempfile.create(['cover', '.webp']) do |tmp|
      file = cover_file(content_type: 'image/webp', tempfile: tmp, size: 100.kilobytes)
      FastImage.stub(:size, [600, 600]) do
        validator = CoverImageValidator.new(file)

        assert_not validator.valid?
        assert_includes validator.errors, 'Співвідношення сторін має бути близько 3:4.'
      end
    end
  end

  test 'invalid when file exceeds max byte size' do
    Tempfile.create(['cover', '.webp']) do |tmp|
      file = cover_file(content_type: 'image/webp', tempfile: tmp, size: 2.megabytes + 1)
      FastImage.stub(:size, [600, 800]) do
        validator = CoverImageValidator.new(file)

        assert_not validator.valid?
        assert_includes validator.errors, 'Розмір файлу обкладинки не може перевищувати 2 МБ.'
      end
    end
  end

  test 'invalid when dimensions cannot be read' do
    Tempfile.create(['cover', '.webp']) do |tmp|
      file = cover_file(content_type: 'image/webp', tempfile: tmp, size: 100.kilobytes)
      FastImage.stub(:size, nil) do
        validator = CoverImageValidator.new(file)

        assert_not validator.valid?
        assert_includes validator.errors, 'Не вдалося визначити розміри зображення.'
      end
    end
  end

  private

  def cover_file(content_type:, tempfile:, size:)
    CoverFile.new(content_type:, tempfile:, size:)
  end
end
