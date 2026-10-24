# frozen_string_literal: true

# Exposes the reader's list filter. Nothing calls it until a page asks, so open catalogue requests stay free.
module ContentFilterable
  extend ActiveSupport::Concern

  included do
    helper_method :current_content_filter, :content_filter_settings_path, :content_filter_change_path
  end

  def current_content_filter
    @current_content_filter ||= ContentFilters::Resolver.call(user: current_user, cookies:)
  end

  def content_filter_settings_path
    studio_index_path(tab: 'profile')
  end

  def content_filter_change_path
    current_user ? content_filter_settings_path : alphabetical_fictions_path
  end
end
