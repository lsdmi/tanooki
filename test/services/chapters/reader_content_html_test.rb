# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ReaderContentHtmlTest < ActiveSupport::TestCase
    test 'normalize replaces nbsp entities and unicode nbsp with regular spaces' do
      html = '<p>Демонів-&nbsp;солдатів,&nbsp;які&nbsp;намагалися</p>'

      assert_equal '<p>Демонів- солдатів, які намагалися</p>', ReaderContentHtml.normalize(html)
    end

    test 'normalize handles numeric nbsp entities' do
      html = '<p>one&#160;two&#xA0;three</p>'

      assert_equal '<p>one two three</p>', ReaderContentHtml.normalize(html)
    end

    test 'render returns normalized chapter content' do
      chapter = chapters(:one)
      chapter.content = '<p>word&nbsp;word</p>'

      assert_includes ReaderContentHtml.render(chapter), 'word word'
      assert_not_includes ReaderContentHtml.render(chapter), '&nbsp;'
    end
  end
end
