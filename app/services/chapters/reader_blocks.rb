# frozen_string_literal: true

module Chapters
  # Tags the reader's text blocks with data-rp-i="0..n" in document order, so a resume position can be stored
  # as a block index (Action Text has no paragraph ids). Containers are walked into; leaves without visible
  # content are skipped. A leaf split by <br> gets one span per line run, since some imports keep a whole
  # chapter in a single <p>. The digest covers every block's text and the block count, so it changes whenever
  # a stored index could point somewhere else.
  #
  # A <div> whose only content is whitespace (often a &nbsp; paragraph spacer, later normalized to a regular
  # space) collapses to zero height in the browser. Pad it with a <br> so the blank line survives. Empty <p>
  # spacers stay collapsed: paragraph margins already separate those chapters.
  class ReaderBlocks
    INDEX_ATTRIBUTE = 'data-rp-i'
    DIGEST_LENGTH = 16
    BLOCK_TAGS = %w[
      address article aside blockquote details div dl figure footer h1 h2 h3 h4 h5 h6 header hr li main nav ol p
      pre section table ul
    ].to_set.freeze
    MEDIA_TAGS = %w[img picture video iframe svg].freeze
    MEDIA_SELECTOR = MEDIA_TAGS.join(', ').freeze
    SPACER_TAG = 'div'

    def initialize(html)
      @fragment = Nokogiri::HTML5.fragment(html.to_s)
      @texts = []
      walk(@fragment)
    end

    def html
      ActiveSupport::SafeBuffer.new(@fragment.to_html)
    end

    def digest
      Digest::SHA256.hexdigest(@texts.join("\n")).first(DIGEST_LENGTH)
    end

    private

    def walk(parent)
      parent.element_children.each do |node|
        next walk(node) if container?(node)
        next pad_spacer(node) if collapsed_spacer?(node)

        runs = line_runs(node)
        if runs.size > 1
          runs.each { |run| tag(wrap(run)) }
        elsif visible?(node)
          tag(node)
        end
      end
    end

    def container?(node)
      node.element_children.any? { |child| BLOCK_TAGS.include?(child.name) }
    end

    def line_runs(node)
      return [] if node.element_children.none? { |child| child.name == 'br' }

      node.children
          .chunk_while { |left, right| left.name != 'br' && right.name != 'br' }
          .select { |run| run.any? { |child| visible?(child) } }
    end

    def visible?(node)
      return true if node.text.match?(/\S/)

      node.element? && (MEDIA_TAGS.include?(node.name) || node.at_css(MEDIA_SELECTOR).present?)
    end

    def collapsed_spacer?(node)
      return false unless node.name == SPACER_TAG
      return false if node.element_children.any?
      return false if visible?(node)

      node.text.match?(/[[:space:]]/)
    end

    def pad_spacer(node)
      node.add_child(@fragment.document.create_element('br'))
    end

    def wrap(run)
      span = @fragment.document.create_element('span')
      run.first.add_previous_sibling(span)
      run.each { |child| span.add_child(child) }
      span
    end

    def tag(node)
      node[INDEX_ATTRIBUTE] = @texts.size.to_s
      @texts << node.text.squish
    end
  end
end
