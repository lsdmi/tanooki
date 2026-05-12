# frozen_string_literal: true

# Dynamic sitemap at /sitemap.xml for search engines (see https://www.sitemaps.org/).
class SitemapsController < ApplicationController
  layout false

  def show
    expires_in 6.hours, public: true if Rails.env.production?
    @entries = Sitemaps::EntryBuilder.new(sitemap_url_options).to_a
  end

  private

  def sitemap_url_options
    opts = Rails.application.config.action_mailer.default_url_options.symbolize_keys.dup
    opts[:protocol] = Rails.env.production? ? 'https' : request.scheme
    opts
  end
end
