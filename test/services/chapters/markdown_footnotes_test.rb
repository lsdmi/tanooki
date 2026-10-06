# frozen_string_literal: true

require 'test_helper'

module Chapters
  class MarkdownFootnotesTest < ActiveSupport::TestCase
    def html(markdown)
      Nokogiri::HTML5.fragment(MarkdownToHtml.call(markdown))
    end

    def notes(markdown)
      html(markdown).css('span.note-reference')
    end

    test 'a footnote becomes a note on the word before the marker' do
      fragment = html("Секта Небесного Меча[^1] чекала.\n\n[^1]: Одна з великих сект.")
      note = fragment.at_css('span.note-reference')

      assert_equal ['Меча', 'Одна з великих сект.'], [note.text, note['data-note']]
      assert_equal 'Секта Небесного Меча чекала.', fragment.at_css('p').text
      assert_empty fragment.css('section, sup, ol')
    end

    test 'note ids follow the composer format' do
      freeze_time do
        assert_equal "note-#{(Time.current.to_f * 1000).to_i}-1",
                     notes("Ци[^1]\n\n[^1]: Енергія.").first['data-note-id']
      end
    end

    test 'punctuation before the marker stays outside the note' do
      fragment = html("— Мушу,[^1] — відповів він.[^2]\n\n[^1]: Перша.\n[^2]: Друга.")

      assert_equal %w[Мушу він], fragment.css('span.note-reference').map(&:text)
      assert_equal '— Мушу, — відповів він.', fragment.at_css('p').text
    end

    test 'a marker after bold text wraps the whole bold name' do
      assert_equal 'Ці Хуей', notes("А **Ці Хуей**[^1] мовчав.\n\n[^1]: Старійшина.").first.at_css('strong').text
    end

    test 'words with apostrophes and hyphens are kept whole' do
      assert_equal %w[будь-що п’ять],
                   notes("Він з'їв будь-що[^1] і п’ять[^2].\n\n[^1]: Перша.\n[^2]: Друга.").map(&:text)
    end

    test 'note text is plain, one line, without the back link' do
      assert_equal 'Енергія з жирним і "лапками" на два рядки.',
                   notes("Ци[^n]\n\n[^n]: Енергія з **жирним** і \"лапками\"\nна два рядки.").first['data-note']
    end

    test 'every marker gets its own id, and a reused footnote repeats its text' do
      spans = notes("Один[^1] два[^2] три[^1]\n\n[^1]: Перша.\n[^2]: Друга.")

      assert_equal 3, spans.pluck('data-note-id').uniq.size
      assert_equal %w[Перша. Друга. Перша.], spans.pluck('data-note')
    end

    test 'a marker with no word before it shows its number' do
      assert_equal %w[1 подвійний 3],
                   notes("[^1] на початку і подвійний[^2][^3]\n\n[^1]: Перша.\n[^2]: Друга.\n[^3]: Третя.").map(&:text)
    end

    test 'a notes heading right above the footnotes is removed' do
      ['**Примітки перекладача:**', '## Notes', 'Примечания'].each do |heading|
        assert_equal ['Ци'], html("Ци[^1]\n\n#{heading}\n\n[^1]: Енергія.").element_children.map(&:text)
      end
    end

    test 'a notes line stays when the answer has no footnotes or it is not the last block' do
      assert_equal '<p>Примітки: див. нижче</p>', MarkdownToHtml.call('Примітки: див. нижче')
      assert_equal 2, html("Примітки:\n\nЦи[^1]\n\n[^1]: Енергія.").css('p').size
    end

    test 'a marker without a definition stays as typed' do
      assert_equal '<p>Текст[^9] без примітки</p>', MarkdownToHtml.call('Текст[^9] без примітки')
    end
  end
end
