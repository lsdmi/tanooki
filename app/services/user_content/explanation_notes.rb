# frozen_string_literal: true

module UserContent
  # Turns an author's text color into one theme-aware note. A fixed hex cannot be read on both
  # light and dark backgrounds, so every stored `color` (gray, blue, red, anything else) becomes
  # the `explanation` class. The database stays as it is; the reader, the editor's first load,
  # and EPUB apply this before the page is shown.
  #
  # A translator note whose color was stripped on a later save is left as a whole italic paragraph
  # starting with `(1)`. That paragraph gets the same class. Italic inside a sentence does not.
  class ExplanationNotes
    CLASS_NAME = 'explanation'
    TEXT_COLOR = %w[color -webkit-text-fill-color].freeze
    FOOTNOTE = /\A\(\d+\)/

    def self.call(html)
      new.apply(html.to_s)
    end

    # `to_s` runs the Action Text sanitizer; `body.to_html` would print stored HTML unsanitized.
    def self.html_for(rich_text)
      return ActiveSupport::SafeBuffer.new if rich_text.blank?

      ActiveSupport::SafeBuffer.new(call(rich_text.to_s))
    end

    def apply(html)
      return html unless html.match?(/color\s*:|<\s*(?:em|i)\b/i)

      fragment = Nokogiri::HTML5.fragment(html)
      return html if promote(fragment).empty?

      rendered = fragment.to_html
      html.html_safe? ? ActiveSupport::SafeBuffer.new(rendered) : rendered
    end

    private

    # Returns the nodes that became notes.
    def promote(fragment)
      colored = fragment.css('[style]').select { |node| text_color?(node) }
      footnotes = fragment.css('em, i').select { |node| bare_footnote?(node) }
      colored.each { |node| strip_text_color(node) }
      (colored + footnotes).each { |node| add_class(node) }
    end

    def text_color?(node)
      declarations(node).any? { |declaration| text_color_declaration?(declaration) }
    end

    def strip_text_color(node)
      kept = declarations(node).reject { |declaration| text_color_declaration?(declaration) }
      if kept.empty?
        node.remove_attribute('style')
      else
        node['style'] = kept.join('; ')
      end
    end

    def declarations(node)
      node['style'].to_s.split(';').map(&:strip).reject(&:empty?)
    end

    def text_color_declaration?(declaration)
      TEXT_COLOR.include?(declaration.split(':', 2).first.to_s.strip.downcase)
    end

    def bare_footnote?(node)
      return false if explanation?(node)

      parent = node.parent
      return false unless parent&.element? && parent.name == 'p'

      parent.element_children.to_a == [node] && parent.text.squish.match?(FOOTNOTE)
    end

    def add_class(node)
      classes = node['class'].to_s.split
      return if classes.include?(CLASS_NAME)

      node['class'] = (classes + [CLASS_NAME]).join(' ')
    end

    def explanation?(node)
      node['class'].to_s.split.include?(CLASS_NAME)
    end
  end
end
