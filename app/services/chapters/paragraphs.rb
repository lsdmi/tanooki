# frozen_string_literal: true

module Chapters
  # Top-level blocks of a chapter body. Untouched blocks keep the HTML they were parsed with.
  class Paragraphs
    Block = Data.define(:html, :markdown)

    def self.list(html)
      blocks(html).each_with_index.map { |block, index| { n: index + 1, markdown: block.markdown } }
    end

    def self.blocks(html)
      Loofah.html5_fragment(html.to_s).children.filter_map { |node| block_for(node) }
    end

    def self.apply(html, edits, changes: [])
      nodes = blocks(html)
      replacements = replacements_for(nodes, edits, changes)
      nodes.each_with_index.flat_map { |block, index| replacements.fetch(index, [block]) }.map(&:html).join
    end

    def self.block_for(node)
      return if node.text? && node.text.blank?
      return Block.new(html: escape_text(node.text), markdown: node.text.squish) if node.text?
      return unless node.element?

      Block.new(html: node.to_html, markdown: markdown_for(node))
    end

    def self.replacements_for(nodes, edits, changes)
      Array(edits).each_with_object({}) do |edit, replacements|
        index = matched_index(nodes, edit)
        replacements[index] = replacement_blocks(edit.to_h.with_indifferent_access[:new], changes)
      end
    end

    def self.matched_index(nodes, edit)
      edit = edit.to_h.with_indifferent_access
      number = edit[:n].to_i
      block = block_at(nodes, number)
      return number - 1 if edit[:old].to_s.squish == block.markdown.squish

      mismatch!(number, block.markdown)
    end

    def self.block_at(nodes, number)
      nodes[number - 1] || raise(Api::Error.new('paragraph_missing', :unprocessable_entity, { n: number }))
    end

    def self.mismatch!(number, markdown)
      raise Api::Error.new('paragraph_mismatch', :unprocessable_entity, { n: number, current: markdown })
    end

    def self.replacement_blocks(markdown, changes)
      return [] if markdown.to_s.strip.empty?

      prepared = Api::Chapters::Content.call(markdown, 'markdown')
      changes.concat(prepared.changes)
      blocks(prepared.html)
    end

    def self.markdown_for(node)
      return '---' if node.name == 'hr'

      "#{heading_prefix(node)}#{inline(node)}".strip
    end

    def self.heading_prefix(node)
      { 'h2' => '## ', 'h3' => '### ', 'h4' => '#### ', 'blockquote' => '> ' }.fetch(node.name, '')
    end

    def self.inline(node)
      node.children.map { |child| inline_child(child) }.join
    end

    def self.inline_child(child)
      return child.text if child.text?

      case child.name
      when 'strong', 'b' then "**#{inline(child)}**"
      when 'em', 'i' then "*#{inline(child)}*"
      when 's' then "~~#{inline(child)}~~"
      when 'br' then "\n"
      when 'a' then "[#{inline(child)}](#{child['href']})"
      else inline(child)
      end
    end

    def self.escape_text(text)
      ERB::Util.html_escape(text)
    end

    private_class_method :block_for, :replacements_for, :matched_index, :block_at, :mismatch!, :replacement_blocks,
                         :markdown_for, :heading_prefix, :inline, :inline_child, :escape_text
  end
end
