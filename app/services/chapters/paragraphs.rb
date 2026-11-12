# frozen_string_literal: true

module Chapters
  # Top-level blocks of a chapter body.
  # Untouched blocks keep the HTML they were parsed with. Edited blocks prefer a surgical text
  # rewrite inside that HTML (styles, dir, notes stay); markdown re-render is only the fallback
  # when the edit changes markdown structure (bold/links/split/…).
  class Paragraphs
    Block = Data.define(:html, :markdown)
    INLINE_TAGS = {
      'strong' => ->(text) { "**#{text}**" }, 'b' => ->(text) { "**#{text}**" },
      'em' => ->(text) { "*#{text}*" }, 'i' => ->(text) { "*#{text}*" },
      's' => ->(text) { "~~#{text}~~" }, 'br' => ->(_) { "\n" }
    }.freeze

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

    def self.markdown_for(node)
      return '---' if node.name == 'hr'

      "#{heading_prefix(node)}#{inline(node)}".strip
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
        edit = edit.to_h.with_indifferent_access
        replacements[index] = replacement_blocks(nodes[index], edit[:new], changes)
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

    def self.replacement_blocks(original, markdown, changes)
      return [] if markdown.to_s.strip.empty?
      return [original] if markdown.to_s.squish == original.markdown.squish
      return [ParagraphSurgery.replace(original, markdown)] if ParagraphSurgery.applicable?(original.markdown, markdown)

      render_markdown_blocks(original, markdown, changes)
    end

    def self.render_markdown_blocks(original, markdown, changes)
      prepared = Api::Chapters::Content.call(markdown, 'markdown')
      changes.concat(prepared.changes)
      rendered = blocks(prepared.html)
      return rendered unless rendered.size == 1

      [ParagraphSurgery.copy_root_attributes(original, rendered.first)]
    end

    def self.heading_prefix(node)
      { 'h1' => '# ', 'h2' => '## ', 'h3' => '### ', 'h4' => '#### ', 'blockquote' => '> ' }.fetch(node.name, '')
    end

    def self.inline(node)
      node.children.map { |child| inline_child(child) }.join
    end

    def self.inline_child(child)
      return child.text if child.text?
      return inline_tag_markdown(child) if INLINE_TAGS.key?(child.name)
      return link_markdown(child) if child.name == 'a'
      return span_markdown(child) if child.name == 'span'

      inline(child)
    end

    def self.inline_tag_markdown(node)
      content = inline(node)
      return '' if content.empty? && node.name != 'br'

      INLINE_TAGS[node.name].call(content)
    end

    def self.link_markdown(node)
      content = inline(node)
      content.empty? ? '' : "[#{content}](#{node['href']})"
    end

    def self.span_markdown(node)
      content = inline(node)
      return '' if content.empty?

      style = node['style'].to_s.downcase
      content = "*#{content}*" if style.match?(/font-style:\s*italic/)
      content = "**#{content}**" if style.match?(/font-weight:\s*(bold|[6-9]00)/)
      content
    end

    def self.escape_text(text)
      ERB::Util.html_escape(text)
    end

    private_class_method :block_for, :replacements_for, :matched_index, :block_at, :mismatch!, :replacement_blocks,
                         :render_markdown_blocks, :heading_prefix, :inline, :inline_child, :inline_tag_markdown,
                         :link_markdown, :span_markdown, :escape_text
  end
end
