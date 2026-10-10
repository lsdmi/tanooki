# frozen_string_literal: true

module UserContent
  # Action Text sanitizer: keeps the app's allowed tags and attributes (config/initializers/action_text.rb) and
  # marks links to other sites as user-generated, so URL reputation scanners do not count them as our own links.
  # Links to other sites that a reader cannot see (no text or image, or hidden) are dropped, keeping their content:
  # scanners treat hidden outbound links as SEO spam on a compromised site.
  # An iframe is kept only for a YouTube embed. Any other frame (another host, http, data:, javascript:) is removed
  # with the tag, for chapters and the blog, because both are Action Text.
  class LinkScrubber < Rails::HTML::PermitScrubber
    EXTERNAL_REL = %w[ugc nofollow noopener noreferrer].freeze
    INTERNAL_HOST = 'baka.in.ua'
    YOUTUBE_EMBED_HOSTS = %w[www.youtube.com www.youtube-nocookie.com].freeze
    YOUTUBE_EMBED_PATH = %r{\A/embed/[A-Za-z0-9_-]+/?\z}
    INVISIBLE_TEXT = /[[:space:]\u200B-\u200D\u2060\uFEFF]/
    HIDDEN_STYLE = /display\s*:\s*none|visibility\s*:\s*hidden/i
    # Text pasted from another site keeps its utility classes (`mx-auto max-w-3xl`), which the site's
    # Tailwind would apply to the article. Only classes the editor itself writes are kept.
    CONTENT_CLASSES = %w[note-reference explanation].freeze

    def self.youtube_embed?(src)
      uri = https_uri(src)
      return false unless uri

      YOUTUBE_EMBED_HOSTS.include?(uri.host.to_s.downcase) && uri.path.match?(YOUTUBE_EMBED_PATH)
    end

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

    def scrub(node)
      if node.element? && node.name == 'iframe' && !self.class.youtube_embed?(node['src'])
        node.remove
        return STOP
      end

      super
    end

    def self.https_uri(src)
      raw = src.to_s.strip
      return if unsafe_src?(raw)

      uri = URI.parse(raw)
      uri if plain_https?(uri)
    rescue URI::InvalidURIError
      nil
    end

    def self.unsafe_src?(raw)
      raw.empty? || raw.match?(/[[:space:]<>"']/)
    end

    def self.plain_https?(uri)
      uri.is_a?(URI::HTTPS) && uri.port == 443 && uri.userinfo.nil?
    end
    private_class_method :https_uri, :unsafe_src?, :plain_https?

    private

    def scrub_attributes(node)
      super
      scrub_classes(node)
      return unless node.name == 'a' && self.class.external?(node['href'])

      if invisible?(node)
        node.before(node.children)
        node.remove
      else
        node['rel'] = (node['rel'].to_s.split | EXTERNAL_REL).join(' ')
      end
    end

    def scrub_classes(node)
      return unless node.key?('class')

      kept = node['class'].split & CONTENT_CLASSES
      kept.empty? ? node.remove_attribute('class') : node['class'] = kept.join(' ')
    end

    def invisible?(node)
      return true if node.key?('hidden') || node['style'].to_s.match?(HIDDEN_STYLE)

      node.text.gsub(INVISIBLE_TEXT, '').empty? && node.at_css('img, iframe').nil?
    end
  end
end
