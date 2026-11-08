# frozen_string_literal: true

module Sitemaps
  # Builds absolute URL entries (loc + optional lastmod) for sitemap.xml: static hubs and indexed models.
  class EntryBuilder
    include Rails.application.routes.url_helpers

    STATIC_URL_HELPERS = %i[
      root_url fictions_url alphabetical_fictions_url calendar_fictions_url tales_url youtube_videos_url
      translation_requests_url about_url friends_url rules_url privacy_url
    ].freeze

    def initialize(default_url_options)
      @default_url_options = default_url_options
    end

    def to_a
      entries = static_entries + fiction_entries + tale_entries + youtube_video_entries + scanlator_entries +
                genre_entries
      entries += if Contests::PublicAccess.listed?
                   contest_static_and_show_entries
                 else
                   public_show_contest_entries
                 end
      entries
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
      Fiction.order(:id).pluck(:slug, :updated_at, :last_chapter_at).map do |slug, updated_at, last_chapter_at|
        entry(:fiction_url, slug, lastmod: [updated_at, last_chapter_at].compact.max)
      end
    end

    def tale_entries
      Publication.published.order(:id).pluck(:slug, :updated_at).map do |slug, updated_at|
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

    def contest_static_and_show_entries
      [entry(:contests_url)] + contest_entries
    end

    # Allowlisted archive shows only — hub stays out until LISTED.
    def public_show_contest_entries
      contest_url_entries(Contests::PublicAccess.discoverable_contests)
    end

    # Visible contests only (published + announced; drafts stay out of the sitemap).
    def contest_entries
      contest_url_entries(Contest.visible)
    end

    def contest_url_entries(scope)
      scope.order(:id)
           .pluck(:slug, :updated_at, :results_published_at)
           .map do |slug, updated_at, results_published_at|
        entry(:contest_url, slug, lastmod: [updated_at, results_published_at].compact.max)
      end
    end
  end
end
