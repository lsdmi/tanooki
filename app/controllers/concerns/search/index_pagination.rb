# frozen_string_literal: true

module Search
  # Per-section page sizes and visibility flags for search results.
  module IndexPagination
    extend ActiveSupport::Concern

    VIDEOS_PER_PAGE = 4
    VIDEOS_FILTER_PER_PAGE = 8

    private

    def fiction_per_page
      case params[:filter]
      when 'fiction' then 24
      when 'blog', 'video' then 1
      else 12
      end
    end

    def publication_per_page
      return 1 if %w[fiction video].include?(params[:filter])

      7
    end

    def video_per_page
      case params[:filter]
      when 'video' then VIDEOS_FILTER_PER_PAGE
      when 'fiction', 'blog' then 1
      else VIDEOS_PER_PAGE
      end
    end

    def show_fictions?
      all_filter? || params[:filter] == 'fiction'
    end

    def show_publications?
      all_filter? || params[:filter] == 'blog'
    end

    def show_videos?
      all_filter? || params[:filter] == 'video'
    end

    def all_filter?
      %w[fiction blog video].exclude?(params[:filter])
    end
  end
end
