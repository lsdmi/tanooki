# frozen_string_literal: true

require 'test_helper'

module Chapters
  # Whole answers shaped like ChatGPT and Claude translations.
  class MarkdownToHtmlChatAnswersTest < ActiveSupport::TestCase
    def answer(name)
      Nokogiri::HTML5.fragment(MarkdownToHtml.call(file_fixture("markdown/#{name}.md").read))
    end

    test 'ChatGPT: heading, scene breaks and footnotes' do
      fragment = answer('chatgpt_translation')

      assert_equal 'Розділ 250. Тінь над містом', fragment.at_css('h3').text
      assert_equal 2, fragment.css('hr').size
      assert_equal %w[Меча ци], fragment.css('span.note-reference').map(&:text)
    end

    test 'ChatGPT: bold names, italic thoughts and system messages' do
      fragment = answer('chatgpt_translation')

      assert_equal 'Су Юе', fragment.at_css('p strong').text
      assert_includes fragment.css('em').map(&:text), 'Якщо я помилюся, усе скінчиться сьогодні'
      assert_includes fragment.css('strong').map(&:text), '[Система]: Ви отримали навичку «Крок тіні» (рівень 1).'
    end

    test 'ChatGPT: no footnote leftovers' do
      fragment = answer('chatgpt_translation')

      assert_empty fragment.css('section, sup, pre')
      assert_not_includes fragment.text, '[^'
      assert_not_includes fragment.text, 'Примітки перекладача'
    end

    test 'Claude: indented paragraphs are text, not code' do
      fragment = answer('claude_translation')

      assert_empty fragment.css('pre, code')
      assert fragment.css('p').first.text.start_with?('Лін Фань ступив у тінь')
    end

    test 'Claude: heading, scene break, note and a system message in angle brackets' do
      fragment = answer('claude_translation')

      assert_equal ['Розділ 251: Крок тіні', 1], [fragment.at_css('h2').text, fragment.css('hr').size]
      assert_equal 'тіні', fragment.at_css('span.note-reference').text
      assert_includes fragment.css('p').map(&:text), '<Попередження: витривалість 12/100>'
    end
  end
end
