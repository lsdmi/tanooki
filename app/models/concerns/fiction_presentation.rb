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

  def related_fictions
    Rails.cache.fetch("related-to-#{slug}", expires_in: 24.hours) do
      Fiction.joins(:scanlators)
             .includes(:genres)
             .where(scanlators: { id: scanlators.pluck(:id) })
             .includes(:cover_attachment)
             .where.not(id: id)
             .order(views: :desc)
             .distinct
    end
  end

  def finished_and_complete?
    unique_chapters = chapters.to_a.uniq { |obj| [obj.number, obj.volume_number] }
    unique_chapters.size >= total_chapters && status.to_sym == :finished
  end
end
