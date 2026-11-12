# frozen_string_literal: true

require 'diff/lcs'

module Chapters
  # Text-only paragraph_edits: rewrite characters inside the stored HTML so styles and notes stay.
  class ParagraphSurgery
    STRUCTURE_TOKEN = /
      \*\*
      | ~~
      | !\[[^\]]*\]\([^)]*\)
      | \[[^\]]*\]\([^)]*\)
      | \[\^[^\]]+\]
      | \#{1,4}(?=\s)
      | (?<!\*)\*(?!\*)
      | (?<!_)_(?!_)
    /x
    MARKDOWN_STRIPS = [
      [/\*\*(.+?)\*\*/m, '\1'],
      [/(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)/m, '\1'],
      [/__(.+?)__/m, '\1'],
      [/(?<!_)_(?!_)(.+?)(?<!_)_(?!_)/m, '\1'],
      [/~~(.+?)~~/m, '\1'],
      [/!\[(.*?)\]\([^)]*\)/m, '\1'],
      [/\[(.*?)\]\([^)]*\)/m, '\1'],
      [/\[\^[^\]]+\]/, '']
    ].freeze

    def self.applicable?(old_markdown, new_markdown)
      return false if new_markdown.to_s.strip.match?(/\A(?:---|\*\*\*)\z/)

      line_breaks(old_markdown) == line_breaks(new_markdown) &&
        structure(old_markdown) == structure(new_markdown)
    end

    def self.replace(original, markdown)
      fragment = Loofah.html5_fragment(original.html)
      root = fragment.children.find(&:element?) || fragment.children.first
      rewrite_text!(root, visible_text(markdown))
      Paragraphs::Block.new(html: root.to_html, markdown: Paragraphs.markdown_for(root))
    end

    def self.copy_root_attributes(original, rendered)
      old_root, new_root = roots(original.html, rendered.html)
      return rendered unless old_root&.name == new_root&.name && old_root

      merge_attributes!(old_root, new_root)
      Paragraphs::Block.new(html: new_root.to_html, markdown: Paragraphs.markdown_for(new_root))
    end

    def self.roots(*htmls)
      htmls.map { |html| Loofah.html5_fragment(html).children.find(&:element?) }
    end

    def self.merge_attributes!(old_root, new_root)
      old_root.attribute_nodes.each { |attribute| new_root[attribute.name] ||= attribute.value }
    end

    def self.structure(text) = text.to_s.scan(STRUCTURE_TOKEN)

    # Soft/hard breaks in markdown are `<br>` placeholders, not characters in HTML text nodes.
    def self.line_breaks(text) = text.to_s.scan(/\n+/)

    def self.visible_text(markdown)
      strip_inline(markdown.to_s.sub(/\A\#{1,4}\s+/, '').sub(/\A>\s+/, '')).delete("\n")
    end

    def self.strip_inline(text)
      loop do
        stripped = MARKDOWN_STRIPS.reduce(text) { |memo, (pattern, replacement)| memo.gsub(pattern, replacement) }
        return text if stripped == text

        text = stripped
      end
    end

    def self.rewrite_text!(root, new_text)
      nodes = root.xpath('.//text()')
      return seed_text!(root, new_text) if nodes.empty?

      old_text = nodes.map(&:content).join
      return if old_text == new_text

      apply_diff!(nodes, old_text, new_text)
    end

    def self.seed_text!(root, new_text)
      root.add_child(Nokogiri::XML::Text.new(new_text, root.document)) if new_text.present?
    end

    def self.apply_diff!(nodes, old_text, new_text)
      pieces = Array.new(nodes.size) { +'' }
      Diff::LCS.sdiff(old_text.chars, new_text.chars).each do |change|
        append_change!(pieces, nodes, old_text.length, change)
      end
      nodes.each_with_index { |node, index| node.content = pieces[index] }
    end

    def self.append_change!(pieces, nodes, old_length, change)
      case change.action
      when '=', '!'
        pieces[node_index_at(nodes, change.old_position)] << change.new_element
      when '+'
        pieces[node_index_for_insert(nodes, change.old_position, old_length)] << change.new_element
      end
    end

    def self.node_index_at(nodes, position)
      offset = 0
      nodes.each_with_index do |node, index|
        next_offset = offset + node.content.length
        return index if position < next_offset || index == nodes.size - 1

        offset = next_offset
      end
      nodes.size - 1
    end

    def self.node_index_for_insert(nodes, position, old_length)
      return nodes.size - 1 if position >= old_length
      return 0 if position <= 0

      node_index_at(nodes, position - 1)
    end

    private_class_method :structure, :line_breaks, :visible_text, :strip_inline, :rewrite_text!, :seed_text!,
                         :apply_diff!, :append_change!, :node_index_at, :node_index_for_insert, :roots,
                         :merge_attributes!
  end
end
