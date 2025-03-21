# frozen_string_literal: true

module UrlHelper
  def format_url(url)
    url.start_with?('http') ? url : "https://#{url}"
  end
end
