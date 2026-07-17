# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubCoverContentTest < ActiveSupport::TestCase
    test 'uses manifest href instead of inline data uri' do
      chapter = chapters(:one)

      html = EpubCoverContent.new(chapter, volume_title: 'Том 1', cover_href: '../images/cover.jpg').build

      assert_includes html, '../images/cover.jpg'
      assert_not_includes html, 'data:image'
    end

    test 'omits image tag when cover href is missing' do
      chapter = chapters(:one)

      html = EpubCoverContent.new(chapter, volume_title: 'Том 1', cover_href: nil).build

      assert_not_includes html, '<img'
    end
  end
end
