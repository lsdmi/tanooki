# frozen_string_literal: true

module UserContent
  # Pasted empty wrappers (Google Docs `docs-internal-guid` strongs) serialize as `****` in markdown.
  module EmptyInlines
    TAGS = %w[strong b em i u s].freeze

    def self.remove!(node, media: 'img, br, iframe')
      return unless node.element? && node.parent
      return unless TAGS.include?(node.name)
      return if node.at_css(media)
      return if node.text.match?(/\S/)

      node.remove
    end
  end
end
