# frozen_string_literal: true

# Public API and related-content helpers for {Fiction}.
module FictionPresentation
  extend ActiveSupport::Concern

  def as_hikka_json
    routes = Rails.application.routes.url_helpers
    public_url_options = Rails.application.config.action_mailer.default_url_options.symbolize_keys

    {
      alternative_title: alternative_title,
      cover_url: routes.rails_blob_url(cover, only_path: false, **public_url_options),
      description: description,
      english_title: english_title,
      reference: routes.fiction_url(self, only_path: false, **public_url_options),
      title: title
    }
  end

  def similar_fictions
    Fictions::SimilarFictions.new(self).fictions
  end
end
