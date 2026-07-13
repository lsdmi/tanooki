# frozen_string_literal: true

require 'test_helper'

module Fictions
  class CoverQualityTest < ActiveSupport::TestCase
    include CoverUploadHelper

    test 'returns fail when cover is missing' do
      fiction = fictions(:two)
      fiction.cover.purge if fiction.cover.attached?

      result = CoverQuality.call(fiction)

      assert_predicate result, :fail?
      assert_includes result.reasons, 'Обкладинка відсутня.'
    end

    test 'returns ok for modern format at minimum dimensions' do
      fiction = fictions(:one)
      fiction.cover.attach(valid_cover_upload)
      fiction.cover.blob.update!(metadata: { 'width' => 600, 'height' => 800, 'analyzed' => true })

      result = CoverQuality.call(fiction)

      assert_predicate result, :ok?
      assert_empty result.reasons
      assert_equal [600, 800], result.metadata.values_at(:width, :height)
    end

    test 'reads dimensions from blob metadata without fast image' do
      fiction = fictions(:one)
      fiction.cover.attach(valid_cover_upload)
      fiction.cover.blob.update!(metadata: { 'width' => 600, 'height' => 800, 'analyzed' => true })

      FastImage.stub(:size, ->(*) { raise 'FastImage should not be called' }) do
        result = CoverQuality.call(fiction)

        assert_predicate result, :ok?
      end
    end

    test 'returns ok for legacy format with acceptable dimensions' do
      fiction = fictions(:one)
      attach_legacy_cover(fiction)

      FastImage.stub(:size, [600, 800]) do
        result = CoverQuality.call(fiction)

        assert_predicate result, :ok?
        assert_empty result.reasons
      end
    end

    test 'returns fail when dimensions are below minimum' do
      fiction = fictions(:one)
      fiction.cover.attach(valid_cover_upload)

      FastImage.stub(:size, [500, 700]) do
        result = CoverQuality.call(fiction)

        assert_predicate result, :fail?
        assert_includes result.reasons, 'Ширина обкладинки має бути не менше 600px.'
        assert_includes result.reasons, 'Висота обкладинки має бути не менше 800px.'
      end
    end

    test 'returns warn when aspect ratio is outside tolerance' do
      fiction = fictions(:one)
      fiction.cover.attach(valid_cover_upload)

      FastImage.stub(:size, [800, 800]) do
        result = CoverQuality.call(fiction)

        assert_predicate result, :warn?
        assert_includes result.reasons, 'Співвідношення сторін обкладинки має бути близько 3:4.'
      end
    end

    test 'returns fail when dimensions cannot be read' do
      fiction = fictions(:one)
      fiction.cover.attach(valid_cover_upload)

      FastImage.stub(:size, nil) do
        result = CoverQuality.call(fiction)

        assert_predicate result, :fail?
        assert_includes result.reasons, 'Не вдалося визначити розміри зображення.'
      end
    end

    private

    def attach_legacy_cover(fiction)
      fiction.cover.attach(
        io: File.open(VALID_COVER_PATH),
        filename: 'cover.png',
        content_type: 'image/png'
      )
      fiction.cover.blob.update!(content_type: 'image/png')
    end
  end
end
