# frozen_string_literal: true

module UserContent
  # Action Text sanitizer: keeps the app's allowed tags and attributes (config/initializers/action_text.rb) and
  # marks links to other sites as user-generated, so URL reputation scanners do not count them as our own links.
  # Links to other sites that a reader cannot see (no text or image, or hidden) are dropped, keeping their content:
  # scanners treat hidden outbound links as SEO spam on a compromised site.
  class LinkScrubber < Rails::HTML::PermitScrubber
    EXTERNAL_REL = %w[ugc nofollow noopener noreferrer].freeze
    INTERNAL_HOST = 'baka.in.ua'
    INVISIBLE_TEXT = /[[:space:]\u200B-\u200D\u2060\uFEFF]/
    HIDDEN_STYLE = /display\s*:\s*none|visibility\s*:\s*hidden/i

    def initialize(tags:, attributes:)
      super()
      self.tags = tags
      self.attributes = attributes
    end

    def self.external?(href)
      host = URI.parse(href.to_s.strip).host
      host.present? && host.downcase != INTERNAL_HOST
    rescue URI::InvalidURIError
      false
    end

    private

    def scrub_attributes(node)
      super
      return unless node.name == 'a' && self.class.external?(node['href'])

      if invisible?(node)
        node.before(node.children)
        node.remove
      else
        node['rel'] = (node['rel'].to_s.split | EXTERNAL_REL).join(' ')
      end
    end

    def invisible?(node)
      return true if node.key?('hidden') || node['style'].to_s.match?(HIDDEN_STYLE)

      node.text.gsub(INVISIBLE_TEXT, '').empty? && node.at_css('img, iframe').nil?
    end
  end
end
