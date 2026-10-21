# frozen_string_literal: true

# Exposes the reader's list filter. Nothing calls it until a page asks, so open catalogue requests stay free.
module ContentFilterable
  extend ActiveSupport::Concern

  included do
    helper_method :current_content_filter
  end

  def current_content_filter
    @current_content_filter ||= ContentFilters::Resolver.call(user: current_user, cookies:)
  end
end
