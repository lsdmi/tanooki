# frozen_string_literal: true

require 'test_helper'

module Library
  class ReadingStateHelperTest < ActionView::TestCase
    include ReadingStateHelper

    test 'delegates ordered_chapters to ChapterCatalog' do
      fiction = fictions(:one)

      assert_equal ChapterCatalog.ordered_chapters(fiction).to_a, ordered_chapters(fiction).to_a
    end

    test 'delegates fiction_epub_download_support to ReadingState' do
      fiction = fictions(:one)

      assert_equal ReadingState.fiction_epub_download_support(fiction, viewer: nil),
                   fiction_epub_download_support(fiction, viewer: nil)
    end
  end
end
