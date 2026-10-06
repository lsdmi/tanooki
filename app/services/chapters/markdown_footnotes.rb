# frozen_string_literal: true

module Chapters
  # Replaces Commonmarker footnotes in a parsed fragment with composer note tooltips: the word (or bold, italic,
  # linked text) right before each marker becomes a `note-reference` span carrying the note text, and the footnote
  # list at the end is removed, along with a "Примітки перекладача:" line left right above it. A marker with nothing
  # to attach to shows its number instead.
  class MarkdownFootnotes
    WRAPPABLE_INLINE = %w[strong em s del b i u code a].freeze
    WORD_AT_END = /(?<word>[\p{L}\p{M}\p{N}][\p{L}\p{M}\p{N}'’ʼ-]*)(?<tail>[^\p{L}\p{M}\p{N}]*)\z/
    NOTES_HEADING = /\A(примітк|примечани|(translator['’]?s? )?(foot)?notes?\b)[^.!?]{0,40}\z/i
    NOTES_HEADING_TAGS = %w[p h1 h2 h3 h4 h5 h6].freeze

    def self.apply(fragment)
      new(fragment).apply
    end

    def initialize(fragment)
      @fragment = fragment
      @document = fragment.document
      @id_base = (Time.current.to_f * 1000).to_i
    end

    def apply
      notes = extract_notes
      @fragment.css('sup.footnote-ref').each_with_index do |marker, index|
        note = notes[marker.at_css('a')&.[]('href').to_s.delete_prefix('#')]
        note.present? ? attach(marker, note_span(note, index + 1)) : marker.remove
      end
    end

    private

    def extract_notes
      section = @fragment.at_css('section.footnotes')
      return {} unless section

      section.remove
      remove_notes_heading
      note_texts(section)
    end

    def remove_notes_heading
      last = @fragment.element_children.last
      return unless last && NOTES_HEADING_TAGS.include?(last.name)

      last.remove if last.text.squish.match?(NOTES_HEADING)
    end

    def note_texts(section)
      section.css('li[id]').to_h do |item|
        item.css('a.footnote-backref').each(&:remove)
        item.css('br').each { |br| br.replace(' ') }
        [item['id'], item.text.squish]
      end
    end

    def note_span(note, number)
      @document.create_element('span', class: 'note-reference', 'data-note' => note,
                                       'data-note-id' => "note-#{@id_base}-#{number}")
    end

    def attach(marker, span)
      anchor = marker.previous_sibling
      match = anchor.content.match(WORD_AT_END) if anchor&.text?

      if match
        wrap_last_word(anchor, match, marker, span)
      elsif anchor&.element? && WRAPPABLE_INLINE.include?(anchor.name)
        anchor.add_next_sibling(span).add_child(anchor)
      else
        marker.add_previous_sibling(span).content = marker.text.strip
      end
      marker.remove
    end

    def wrap_last_word(text_node, match, marker, span)
      text_node.content = text_node.content[0...match.begin(:word)]
      span.content = match[:word]
      marker.add_previous_sibling(span)
      marker.add_previous_sibling(@document.create_text_node(match[:tail])) if match[:tail].present?
    end
  end
end
