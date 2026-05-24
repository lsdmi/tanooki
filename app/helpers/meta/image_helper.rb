# frozen_string_literal: true

module Meta
  # Open Graph image URL resolution by route and page assigns.
  module ImageHelper
    def meta_image
      result_cover = path_to_cover

      if result_cover.is_a?(String) || result_cover&.persisted?
        url_for(result_cover)
      else
        url_for(highlights_cover)
      end
    end

    private

    def fictions_cover
      if params[:action] == 'index'
        meta_assign(:latest_updates)&.first&.cover
      else
        meta_cover
      end
    end

    def youtube_video_cover
      meta_assign(:highlight)&.thumbnail
    end

    def highlights_cover
      asset_path('psyduck_background.webp')
    end

    def results_cover
      meta_assign(:results)&.first&.cover
    end

    def path_to_cover
      case request.path
      when root_path then highlights_cover
      when fictions_path then fictions_cover
      when search_index_path then results_cover
      when youtube_videos_path then youtube_video_cover
      when tales_path then tales_cover
      when %r{^/profile/.*} then user_profile_cover
      else meta_cover
      end
    end

    def user_profile_cover
      meta_assign(:user).avatar.image
    end

    def tales_cover
      meta_assign(:highlights).first.cover
    end
  end
end
