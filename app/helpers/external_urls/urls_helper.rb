# frozen_string_literal: true

require 'uri'

# External link builders and URL helpers for views.
module ExternalUrls
  TELEGRAM_PROFILE_BASE = 'https://telegram.me/'
  TELEGRAM_SITE_HANDLE = 'bakaInUa'
  BUYMECOFFEE_URL = 'https://www.buymeacoffee.com/bakaInUa'

  def self.profile_url(telegram_id)
    handle = telegram_id.to_s.delete_prefix('@')
    return if handle.blank?

    "#{TELEGRAM_PROFILE_BASE}#{handle}"
  end

  def self.site_url
    profile_url(TELEGRAM_SITE_HANDLE)
  end

  # Normalizes external URLs and linkifies http(s) substrings in plain text.
  module UrlsHelper
    DEFAULT_LINKIFY_LINK_CLASS =
      'underline text-sky-700 dark:text-sky-400 hover:text-sky-900 dark:hover:text-sky-300 break-words'

    HTTP_URL_PATTERN = URI::DEFAULT_PARSER.make_regexp(%w[http https]).freeze

    def https_url(url)
      s = url.to_s
      return s if s.blank?

      s.start_with?('http') ? s : "https://#{s}"
    end

    def telegram_profile_url(telegram_id)
      ExternalUrls.profile_url(telegram_id)
    end

    def telegram_site_url
      ExternalUrls.site_url
    end

    def buymeacoffee_site_url
      ExternalUrls::BUYMECOFFEE_URL
    end

    # Plain text with http(s) URLs turned into external links. HTML in the source is escaped.
    def linkify_urls(text, link_class: DEFAULT_LINKIFY_LINK_CLASS)
      return if text.blank?

      sanitize(linkified_html(text, link_class), tags: %w[a], attributes: %w[href target rel class])
    end

    private

    def linkified_html(text, link_class)
      html = ActiveSupport::SafeBuffer.new
      offset = 0
      while (m = HTTP_URL_PATTERN.match(text, offset))
        html << text[offset...m.begin(0)] << link_or_plain_segment(m[0], link_class)
        offset = m.end(0)
      end
      html << text[offset..]
    end

    def link_or_plain_segment(url, link_class)
      return url unless safe_web_url?(url)

      link_to(h(url), url, target: '_blank', rel: 'noopener noreferrer', class: link_class)
    end

    def safe_web_url?(url)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end
  end
end
