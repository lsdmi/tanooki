# frozen_string_literal: true

module Chapters
  # Turns Markdown from AI chat answers (ChatGPT, Claude) into the chapter HTML the TinyMCE composer produces.
  # Footnotes become composer note tooltips (MarkdownFootnotes). Raw HTML is shown as text, never rendered.
  # The output still goes through the content sanitizer before it is saved.
  class MarkdownToHtml
    OPTIONS = {
      parse: { smart: false },
      render: { unsafe: false, escape: true, hardbreaks: true },
      extension: { strikethrough: true, table: true, footnotes: true, autolink: false, tagfilter: false,
                   header_ids: nil }
    }.freeze
    PLUGINS = { syntax_highlighter: nil }.freeze

    # Markdown levels stay: # is h1. The composer offers nothing below h4, so h5 and h6 fold up.
    HEADING_LEVELS = { 'h5' => 'h4', 'h6' => 'h4' }.freeze
    WHOLE_DOCUMENT_OPEN = /\A```[ \t]*(?:markdown|md|text|plaintext)?[ \t]*\z/i
    FENCE_LINE = /\A[ \t]*(```|~~~)/

    def self.call(markdown)
      new(markdown).call
    end

    def initialize(markdown)
      @markdown = markdown.to_s
    end

    def call
      source = prepare(@markdown)
      return '' if source.blank?

      @fragment = Nokogiri::HTML5.fragment(Commonmarker.to_html(source, options: OPTIONS, plugins: PLUGINS))
      MarkdownFootnotes.apply(@fragment)
      demote_headings
      @fragment.css('del').each { |node| node.name = 's' }
      unfence_code_blocks
      unwrap_empty_links
      @fragment.to_html.strip
    end

    private

    def prepare(text)
      text = ReaderContentHtml.normalize(text.gsub(/\r\n?/, "\n"))
      text = unwrap_whole_document_fence(text)
      dedent(text)
    end

    # Line-based unwrap avoids a polynomial regex on attacker-controlled markdown.
    def unwrap_whole_document_fence(text)
      stripped = text.strip
      return text unless stripped.end_with?('```')

      open_end = stripped.index("\n")
      return text unless open_end
      return text unless stripped[0...open_end].match?(WHOLE_DOCUMENT_OPEN)

      without_close = stripped.delete_suffix('```')
      close_line_start = without_close.rindex("\n")
      return text unless close_line_start
      return text unless without_close[(close_line_start + 1)..].match?(/\A[ \t]*\z/)

      without_close[(open_end + 1)...close_line_start]
    end

    # Pasted novel text often indents paragraphs, which CommonMark reads as code blocks. Dropping leading
    # indentation (outside fences) keeps them paragraphs, at the cost of flattening nested lists.
    def dedent(text)
      in_fence = false
      text.each_line.map do |line|
        if line.match?(FENCE_LINE)
          in_fence = !in_fence
          line.lstrip
        else
          in_fence ? line : line.sub(/\A[ \t]+/, '')
        end
      end.join
    end

    def demote_headings
      @fragment.css(HEADING_LEVELS.keys.join(',')).each { |heading| heading.name = HEADING_LEVELS[heading.name] }
    end

    # Text that ChatGPT wrapped in a code fence is still chapter text: each block becomes paragraphs.
    def unfence_code_blocks
      @fragment.css('pre').each do |pre|
        pre.text.strip.split(/\n{2,}/).each { |block| pre.add_previous_sibling(paragraph_with_breaks(block)) }
        pre.remove
      end
    end

    def paragraph_with_breaks(block)
      document = @fragment.document
      paragraph = document.create_element('p')
      block.split("\n").each_with_index do |line, index|
        paragraph.add_child(document.create_element('br')) if index.positive?
        paragraph.add_child(document.create_text_node(line))
      end
      paragraph
    end

    # Commonmarker blanks unsafe URLs (`javascript:`); the link text stays.
    def unwrap_empty_links
      @fragment.css('a').each do |link|
        next if link['href'].present?

        link.children.each { |child| link.add_previous_sibling(child) }
        link.remove
      end
    end
  end
end
