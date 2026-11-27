# frozen_string_literal: true

# Public API and related-content helpers for {Fiction}.
module FictionPresentation
  extend ActiveSupport::Concern

  # Columns copied as they are into as_hikka_json; the two URLs are built there.
  HIKKA_FIELDS = %i[alternative_title description english_title hikka_slug slug title].freeze

  # Keys stay alphabetical. `slug` is the Baka slug, `hikka_slug` the matched Hikka title (nil when unmatched).
  def as_hikka_json
    routes = Rails.application.routes.url_helpers
    url_options = Rails.application.config.action_mailer.default_url_options.symbolize_keys
    url_options = { only_path: false, **url_options }

    slice(*HIKKA_FIELDS).symbolize_keys.merge(
      cover_url: routes.rails_blob_url(cover, **url_options),
      reference: routes.fiction_url(self, **url_options)
    ).sort.to_h
  end

  def similar_fictions
    Fictions::SimilarFictions.new(self).fictions
  end
end
