# frozen_string_literal: true

require 'test_helper'

module UserContent
  class FramePasteTest < ActiveSupport::TestCase
    FRAME = '<p style="white-space: nowrap; background: red; background-color: #ff0000; min-width: 4000px; ' \
            'width: 4000px; padding-left: 2em; font-weight: 700; color: #1f1f1f">Довгий рядок</p>' \
            '<img style="width: 300px" width="300" src="https://example.com/a.png">' \
            '<table width="5000"><tr><td width="5000">x</td></tr></table>' \
            '<style>p { white-space: nowrap; background: red }</style>'

    test 'keeps indent, weight, and color on a framed paragraph' do
      style = fragment.at_css('p')['style']

      assert_includes style, 'padding-left'
      assert_includes style, 'font-weight'
      assert_includes style, 'color'
    end

    test 'drops the red background and the width that stops wrapping' do
      style = fragment.at_css('p')['style']

      assert_not_includes style, 'white-space'
      assert_not_includes style, 'background'
      assert_not_includes style, '4000px'
    end

    test 'keeps an image width and drops a table width' do
      assert_includes fragment.at_css('img')['style'], 'width'
      assert_equal '300', fragment.at_css('img')['width']
      assert_nil fragment.at_css('table')['width']
    end

    test 'drops a pasted stylesheet instead of leaving its css as text' do
      html = rendered

      assert_not_includes html, '<style'
      assert_not_includes html, 'background: red'
    end

    private

    def fragment
      Nokogiri::HTML5.fragment(rendered)
    end

    def rendered
      chapter = chapters(:one)
      chapter.content = FRAME
      chapter.content.to_s
    end
  end
end
