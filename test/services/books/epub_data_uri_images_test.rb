# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubDataUriImagesTest < ActiveSupport::TestCase
    TINY_PNG = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='

    test 'extract replaces data uri src with epub image path and adds manifest item' do
      book = GEPUB::Book.new
      html = %(<p><img src="data:image/png;base64,#{TINY_PNG}"></p>)

      result = EpubDataUriImages.extract!(html, book: book, chapter_key: 'chapter_1')

      assert_includes result, '../images/chapter_1_0'
      assert manifest_item_for(book, 'chapter_1', 0)
    end

    test 'leaves non-data-uri images unchanged' do
      book = GEPUB::Book.new
      html = %(<p><img src="https://example.com/a.png"></p>)

      result = EpubDataUriImages.extract!(html, book: book, chapter_key: 'chapter_1')

      assert_includes result, 'https://example.com/a.png'
      assert_empty book.manifest.items
    end

    test 'extracts multiple inline images with stable indices' do
      book = GEPUB::Book.new
      html = <<~HTML
        <p><img src="data:image/png;base64,#{TINY_PNG}"></p>
        <p><img src="data:image/png;base64,#{TINY_PNG}"></p>
      HTML

      result = EpubDataUriImages.extract!(html, book: book, chapter_key: 'chapter_2')

      assert_includes result, '../images/chapter_2_0'
      assert_includes result, '../images/chapter_2_1'
      assert manifest_item_for(book, 'chapter_2', 0)
    end

    private

    def manifest_item_for(book, chapter_key, index)
      extension = Attachments::VariantProcessing.available? ? 'jpg' : 'png'
      href = "images/#{chapter_key}_#{index}.#{extension}"

      assert_not_nil book.manifest.item_by_href(href)
    end
  end
end
