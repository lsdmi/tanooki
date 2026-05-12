# frozen_string_literal: true

module ExternalUrls
  # Normalizes user-entered site URLs for links: adds https:// when no http(s) scheme is present.
  module HttpsHelper
    def https_url(url)
      s = url.to_s
      return s if s.blank?

      s.start_with?('http') ? s : "https://#{s}"
    end
  end
end
