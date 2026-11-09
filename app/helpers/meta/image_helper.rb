# frozen_string_literal: true

module Meta
  # Open Graph image URL resolution by route and page assigns.
  module ImageHelper
    def meta_image
      return absolute_meta_url(pokemon_battle_cover) if pokemon_battle_cover

      result_cover = path_to_cover
      cover = if result_cover.is_a?(String) || result_cover&.persisted?
                result_cover
              else
                highlights_cover
              end
      absolute_meta_url(cover)
    end

    # Real pixel size when the OG image is an ActiveStorage attachment; omit tags otherwise
    # (hardcoded landscape sizes mis-crop portrait fiction covers in Discord/Telegram).
    def meta_image_dimensions
      return if meta_assign(:pokemon_battle)&.persisted?

      cover = path_to_cover
      return unless cover.respond_to?(:blob) && cover.blob

      width, height = cover.blob.metadata.values_at('width', 'height')
      return if width.blank? || height.blank?

      { width: width.to_i, height: height.to_i }
    end

    private

    def pokemon_battle_cover
      battle = meta_assign(:pokemon_battle)
      return unless battle&.persisted?

      pokemon_battle_og_url(battle)
    end

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
      meta_assign(:highlights)&.first&.cover
    end

    def absolute_meta_url(cover)
      case cover
      when String then absolute_meta_path(cover)
      when ActiveStorage::Attached::One then absolute_attached_meta_url(cover)
      else absolute_blob_or_path_meta_url(cover)
      end
    end

    def absolute_attached_meta_url(cover)
      return absolute_meta_path(highlights_cover) unless cover.attached?

      rails_blob_url(cover, only_path: false, **meta_public_url_options)
    end

    def absolute_blob_or_path_meta_url(cover)
      return rails_blob_url(cover, only_path: false, **meta_public_url_options) if cover.respond_to?(:blob)

      absolute_meta_path(url_for(cover))
    end

    def absolute_meta_path(path)
      value = path.to_s
      return value if value.match?(%r{\Ahttps?://}i)

      path_part = value.start_with?('/') ? value : "/#{value}"
      "#{meta_public_origin}#{path_part}"
    end

    def meta_public_url_options
      Rails.application.config.action_mailer.default_url_options.symbolize_keys
    end

    def meta_public_origin
      opts = meta_public_url_options
      protocol = opts[:protocol].presence || 'http'
      host = opts.fetch(:host)
      port = opts[:port]
      origin = "#{protocol}://#{host}"
      return origin if port.blank? || [80, 443].include?(port.to_i)

      "#{origin}:#{port}"
    end
  end
end
