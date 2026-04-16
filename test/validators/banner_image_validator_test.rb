# frozen_string_literal: true

require 'test_helper'

class BannerImageValidatorTest < ActiveSupport::TestCase
  BannerFile = Struct.new(:content_type, :tempfile)

  test 'valid when file is blank' do
    validator = BannerImageValidator.new(nil)

    assert_predicate validator, :valid?
    assert_empty validator.errors
  end

  test 'valid for webp within min width and aspect tolerance' do
    Tempfile.create(['banner', '.webp']) do |tmp|
      file = BannerFile.new('image/webp', tmp)
      FastImage.stub(:size, [2000, 667]) do
        validator = BannerImageValidator.new(file)

        assert_predicate validator, :valid?
        assert_empty validator.errors
      end
    end
  end

  test 'invalid when not webp' do
    Tempfile.create(['banner', '.webp']) do |tmp|
      file = BannerFile.new('image/png', tmp)
      FastImage.stub(:size, [2000, 667]) do
        validator = BannerImageValidator.new(file)

        assert_not validator.valid?
        assert_includes validator.errors, 'Банер має бути у форматі WebP.'
      end
    end
  end

  test 'invalid when width is below minimum' do
    Tempfile.create(['banner', '.webp']) do |tmp|
      file = BannerFile.new('image/webp', tmp)
      FastImage.stub(:size, [800, 400]) do
        validator = BannerImageValidator.new(file)

        assert_not validator.valid?
        assert_includes validator.errors, 'Ширина банера має бути не менше 1000px.'
      end
    end
  end

  test 'invalid when aspect ratio is outside tolerance' do
    Tempfile.create(['banner', '.webp']) do |tmp|
      file = BannerFile.new('image/webp', tmp)
      FastImage.stub(:size, [1000, 100]) do
        validator = BannerImageValidator.new(file)

        assert_not validator.valid?
        assert_includes validator.errors, 'Співвідношення сторін має бути близько 3.0:1.'
      end
    end
  end

  test 'invalid when dimensions cannot be read' do
    Tempfile.create(['banner', '.webp']) do |tmp|
      file = BannerFile.new('image/webp', tmp)
      FastImage.stub(:size, nil) do
        validator = BannerImageValidator.new(file)

        assert_not validator.valid?
        assert_includes validator.errors, 'Не вдалося визначити розміри зображення.'
      end
    end
  end
end
