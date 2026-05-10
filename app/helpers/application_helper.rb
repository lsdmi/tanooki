# frozen_string_literal: true

# View helpers shared application-wide (canonical URLs, UI hints, text helpers).
module ApplicationHelper
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

  def punch(string)
    sentences = string.scan(/.*?[.?!](?=\s|\z)/)
    result = ''

    sentences.each do |sentence|
      result.length <= 20 ? result += sentence : break
    end

    result.presence || string
  end

  def chapters_show_page?
    controller_name.to_sym == :chapters && action_name.to_sym == :show
  end

  def chapters_show_referer?
    request.referer&.include?('chapters') && controller_name.to_sym == :comments
  end

  def requires_font?
    (controller_name.to_sym == :tales && action_name.to_sym == :show) ||
      (controller_name.to_sym == :chapters && action_name.to_sym == :show)
  end

  def requires_tinymce?
    (controller_name == 'publications' && %w[new edit create update].include?(action_name)) ||
      (controller_name == 'chapters' && %w[new edit create update].include?(action_name))
  end

  def requires_sweetalert?
    controller_name.in?(%w[studio readings])
  end

  def genre_show_page?
    controller_path == 'fictions/genres' && action_name == 'show'
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
