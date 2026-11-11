# frozen_string_literal: true

module Meta
  # Open Graph + Twitter Card type (`og:type`) from the current path.
  module OpenGraphHelper
    WEBSITE_ASSIGN_KEYS = %i[contest scanlator].freeze

    def meta_type
      return 'website' if genre_show_page? || website_meta_assign? || website_meta_path?

      'article'
    end

    # Square team avatars crop poorly as large cards; prefer summary on scanlator show.
    def meta_twitter_card
      meta_assign_persisted?(:scanlator) ? 'summary' : 'summary_large_image'
    end

    private

    def website_meta_assign?
      WEBSITE_ASSIGN_KEYS.any? { |key| meta_assign_persisted?(key) }
    end

    def website_meta_path?
      [
        root_path, search_index_path, fictions_path, youtube_videos_path,
        alphabetical_fictions_path, calendar_fictions_path, tales_path, about_path,
        rules_path, friends_path, privacy_path, translation_requests_path
      ].include?(request.path)
    end
  end
end
