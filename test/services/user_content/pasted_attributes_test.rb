# frozen_string_literal: true

require 'test_helper'

module UserContent
  class PastedAttributesTest < ActiveSupport::TestCase
    PASTED_CHAT = '<div class="mx-auto max-w-3xl px-[var(--x)]" role="log" data-controller="chat" ' \
                  'data-action="click->chat#go"><div class="max-w-[85%] prose">' \
                  '<p class="whitespace-normal">Текст ' \
                  '<span class="note-reference" data-note="Примітка" data-note-id="note-1">слово</span> ' \
                  '<span class="explanation foreign">сіре</span></p></div></div>'

    test 'drops classes pasted from another site and keeps the editor ones' do
      fragment = Nokogiri::HTML5.fragment(rendered_html(PASTED_CHAT))

      assert_equal %w[note-reference explanation], fragment.css('[class]').pluck('class')
    end

    test 'drops data attributes pasted from another site and keeps the note ones' do
      note = Nokogiri::HTML5.fragment(rendered_html(PASTED_CHAT)).at_css('.note-reference')

      assert_equal({ 'data-note' => 'Примітка', 'data-note-id' => 'note-1' },
                   note.attributes.transform_values(&:value).slice('data-note', 'data-note-id'))
      assert_not_includes rendered_html(PASTED_CHAT), 'data-controller'
      assert_not_includes rendered_html(PASTED_CHAT), 'data-action'
    end

    private

    def rendered_html(content)
      chapter = chapters(:one)
      chapter.content = content
      chapter.content.to_s
    end
  end
end
