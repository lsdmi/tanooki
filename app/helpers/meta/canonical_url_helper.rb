# frozen_string_literal: true

module Meta
  # Builds canonical and Open Graph URLs with an allowlisted query string.
  module CanonicalUrlHelper
    PRODUCTION_URL = 'https://baka.in.ua'

    # Query keys allowed on `<link rel="canonical">` / `og:url`; all other keys are dropped.
    CANONICAL_QUERY_ALLOWLIST = %w[search].freeze

    def canonical_url
      uri = canonical_authority_uri
      url = "#{uri.scheme}://#{uri.host}"
      url << ":#{uri.port}" if uri.port != uri.default_port
      url << request.path
      query = canonical_query_string
      url << "?#{query}" if query.present?
      url
    end

    private

    def canonical_authority_uri
      if Rails.env.production?
        URI.parse(PRODUCTION_URL)
      else
        URI.parse(request.base_url)
      end
    end

    def canonical_query_string
      allowed = CANONICAL_QUERY_ALLOWLIST.each_with_object({}) do |key, acc|
        value = request.query_parameters[key]
        acc[key] = value if value.present?
      end
      return '' if allowed.empty?

      Rack::Utils.build_nested_query(allowed)
    end
  end
end
