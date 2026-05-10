# frozen_string_literal: true

# Builds absolute URL entries for sitemap.xml (static hubs + indexed models).
class SitemapEntries
  include Rails.application.routes.url_helpers

  STATIC_URL_HELPERS = %i[
    root_url fictions_url alphabetical_fictions_url calendar_fictions_url tales_url youtube_videos_url
    translation_requests_url rules_url privacy_url
  ].freeze

  def initialize(default_url_options)
    @default_url_options = default_url_options
  end

  def to_a
    static_entries + fiction_entries + tale_entries + youtube_video_entries + scanlator_entries + genre_entries
  end

  private

  attr_reader :default_url_options

  def entry(url_helper_method, *, lastmod: nil, **)
    loc = public_send(url_helper_method, *, **default_url_options, **)
    { loc:, lastmod: lastmod&.utc&.iso8601 }.compact
  end

  def static_entries
    STATIC_URL_HELPERS.map { |helper| entry(helper) }
  end

  def fiction_entries
    Fiction.order(:id).pluck(:slug, :updated_at).map do |slug, updated_at|
      entry(:fiction_url, slug, lastmod: updated_at)
    end
  end

  def tale_entries
    Publication.order(:id).pluck(:slug, :updated_at).map do |slug, updated_at|
      entry(:tale_url, slug, lastmod: updated_at)
    end
  end

  def youtube_video_entries
    YoutubeVideo.order(:id).pluck(:slug, :updated_at).map do |slug, updated_at|
      entry(:youtube_video_url, slug, lastmod: updated_at)
    end
  end

  def scanlator_entries
    Scanlator.order(:id).pluck(:slug, :updated_at).map do |slug, updated_at|
      entry(:scanlator_url, slug, lastmod: updated_at)
    end
  end

  def genre_entries
    Genre.order(:id).pluck(:slug, :updated_at).map do |slug, updated_at|
      entry(:fiction_genre_fictions_url, slug, lastmod: updated_at)
    end
  end
end
