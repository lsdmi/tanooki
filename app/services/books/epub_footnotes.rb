# frozen_string_literal: true

module Books
  # Turns composer note tooltips into EPUB 3 footnotes. E-readers drop +data-note+, so the word
  # becomes a +noteref+ link and the note text moves into an +aside+ at the end of the chapter.
  # Apple Books, Kobo, and KOReader open that aside as a popup. The aside stays in the document
  # (it is not hidden with CSS) so other readers still show the text after the chapter.
  class EpubFootnotes
    ID_PATTERN = /\A[A-Za-z][\w.-]*\z/

    def self.call(html)
      new.apply(html.to_s)
    end

    def apply(html)
      return html unless html.include?('note-reference')

      fragment = Nokogiri::HTML5.fragment(html)
      spans = fragment.css('span.note-reference')
      return html if spans.empty?

      @used_ids = fragment.css('[id]').filter_map { |node| node['id'] }
      @notes = []
      spans.each { |span| convert(span) }
      @notes.each { |id, text| fragment.add_child(footnote_aside(fragment, id, text)) }
      fragment.to_html
    end

    private

    def convert(span)
      text = span['data-note'].to_s.squish
      if text.empty?
        unwrap(span)
        return
      end

      link = reference_link(span.document, allocate_id(span['data-note-id']))
      place_link(span, link, @notes.size + 1)
      @notes << [link['href'].delete_prefix('#'), text]
    end

    # A noteref is itself a link, so it cannot wrap or sit inside another one. Those notes get a
    # superscript marker instead of turning the word into the link.
    def place_link(span, link, number)
      anchor_conflict?(span) ? place_marker(span, link, number) : place_around_word(span, link, number)
    end

    def place_marker(span, link, number)
      link.add_child(span.document.create_element('sup', number.to_s))
      (span.ancestors('a').last || span).add_next_sibling(link)
      unwrap(span)
    end

    def place_around_word(span, link, number)
      span.children.each { |child| link.add_child(child) }
      link.content = number.to_s if link.text.squish.empty? && link.element_children.empty?
      span.replace(link)
    end

    def anchor_conflict?(span)
      span.at_css('a') || span.ancestors('a').any?
    end

    def reference_link(document, id)
      link = document.create_element('a')
      link['href'] = "##{id}"
      link['epub:type'] = 'noteref'
      link['class'] = 'noteref'
      link['role'] = 'doc-noteref'
      link
    end

    def footnote_aside(fragment, id, text)
      aside = fragment.document.create_element('aside')
      aside['id'] = id
      aside['epub:type'] = 'footnote'
      aside['class'] = 'footnote'
      aside['role'] = 'doc-footnote'
      paragraph = fragment.document.create_element('p')
      paragraph.content = text
      aside.add_child(paragraph)
      aside
    end

    def allocate_id(raw)
      base = raw.to_s.strip
      base = 'fn' unless base.match?(ID_PATTERN)
      candidate = base
      suffix = 2
      while @used_ids.include?(candidate)
        candidate = "#{base}-#{suffix}"
        suffix += 1
      end
      @used_ids << candidate
      candidate
    end

    def unwrap(node)
      node.before(node.children)
      node.remove
    end
  end
end
