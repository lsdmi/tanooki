# frozen_string_literal: true

module Meta
  # Open Graph + Twitter Card type (`og:type`) from the current path.
  module OpenGraphHelper
    def meta_type
      return 'website' if genre_show_page?

      case request.path
      when root_path, search_index_path, fictions_path, youtube_videos_path,
           alphabetical_fictions_path, calendar_fictions_path, tales_path, about_path,
           rules_path, privacy_path, translation_requests_path
        'website'
      else
        'article'
      end
    end
  end
end
