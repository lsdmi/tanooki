# frozen_string_literal: true

require 'test_helper'

module Chapters
  class MarkdownToHtmlTest < ActiveSupport::TestCase
    def convert(markdown)
      MarkdownToHtml.call(markdown)
    end

    def html(markdown)
      Nokogiri::HTML5.fragment(convert(markdown))
    end

    test 'blank input gives an empty string' do
      assert_equal '', convert(nil)
      assert_equal '', convert("  \n\n ")
    end

    test 'paragraphs, and a single newline is a line break' do
      assert_equal "<p>Перший рядок<br>\nдругий</p>\n<p>Новий абзац</p>", convert("Перший рядок\nдругий\n\nНовий абзац")
    end

    test 'bold, italic and strikethrough use the composer tags' do
      assert_equal '<p><strong>жирний</strong> <em>курсив</em> <s>закреслений</s></p>',
                   convert('**жирний** *курсив* ~~закреслений~~')
    end

    test 'blockquote' do
      assert_equal "<blockquote>\n<p>Цитата</p>\n</blockquote>", convert('> Цитата')
    end

    test 'scene breaks become hr' do
      ['***', '---', '___', '* * *'].each do |scene_break|
        assert_equal "<p>До</p>\n<hr>\n<p>Після</p>", convert("До\n\n#{scene_break}\n\nПісля"), scene_break
      end
    end

    test 'headings start at h2 and stop at h4, without generated ids' do
      fragment = html("# Один\n\n## Два\n\n### Три\n\n#### Чотири\n\n##### П'ять\n\n###### Шість")

      assert_equal %w[h2 h2 h3 h4 h4 h4], fragment.element_children.map(&:name)
      assert_nil fragment.at_css('[id]')
    end

    test 'lists' do
      fragment = html("- один\n- два\n\n1. перший")

      assert_equal %w[один два], fragment.css('ul li').map(&:text)
      assert_equal %w[перший], fragment.css('ol li').map(&:text)
    end

    test 'tables' do
      fragment = html("| Ім'я | Ранг |\n|---|---|\n| Лін | 3 |")

      assert_equal ["Ім'я", 'Ранг'], fragment.css('table thead th').map(&:text)
      assert_equal %w[Лін 3], fragment.css('table tbody td').map(&:text)
    end

    test 'links keep http targets and lose unsafe ones' do
      fragment = html('[сайт](https://example.com) і [погане](javascript:alert(1))')

      assert_equal ['https://example.com'], fragment.css('a').pluck('href')
      assert_includes fragment.text, 'погане'
    end

    test 'raw HTML is shown as text, never rendered' do
      fragment = html("<script>alert(1)</script>\n\nТекст <b>жирний</b> і <System>")

      assert_empty fragment.css('script, b')
      assert_includes fragment.text, '<script>alert(1)</script>'
      assert_includes fragment.text, '<System>'
    end

    test 'stray asterisks stay as typed' do
      assert_equal '<p>Зірочки ** тут ** і *невідкритий, б**ть</p>', convert('Зірочки ** тут ** і *невідкритий, б**ть')
    end

    test 'indented paragraphs stay paragraphs, not code' do
      fragment = html("    Абзац з відступом і **жирним**.\n\n\tЩе один.")

      assert_empty fragment.css('pre, code')
      assert_equal ['Абзац з відступом і жирним.', 'Ще один.'], fragment.css('p').map(&:text)
      assert fragment.at_css('p strong')
    end

    test 'a whole answer wrapped in a code fence is unwrapped and converted' do
      assert_equal "<h2>Розділ</h2>\n<p>Текст <em>курсив</em></p>",
                   convert("```markdown\n## Розділ\n\nТекст *курсив*\n```")
    end

    test 'a code block inside the text becomes plain paragraphs' do
      fragment = html("До\n\n```\nрядок один\nрядок два\n\n<b>інший</b> абзац\n```\n\nПісля")

      assert_empty fragment.css('pre, code, b')
      assert_equal ['До', 'рядок одинрядок два', '<b>інший</b> абзац', 'Після'], fragment.css('p').map(&:text)
      assert_equal 1, fragment.css('p br').size
    end

    test 'Windows line endings and non-breaking spaces are normalized' do
      assert_equal "<p>Рядок один<br>\nрядок два</p>", convert("Рядок\u00A0один\r\nрядок&nbsp;два")
    end
  end
end
