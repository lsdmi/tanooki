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

    test 'render tags resume blocks' do
      chapter = chapters(:one)
      chapter.content = '<p>one</p><p>two</p>'

      assert_equal 2, Nokogiri::HTML5.fragment(ReaderContentHtml.render(chapter)).css('p[data-rp-i]').size
    end

    test 'digest changes when chapter content changes' do
      chapter = chapters(:one)
      chapter.content = '<p>one</p><p>two</p>'
      digest = ReaderContentHtml.new(chapter).digest
      chapter.content = '<p>one</p><p>two, edited</p>'

      assert_not_equal digest, ReaderContentHtml.new(chapter).digest
    end
  end
end
