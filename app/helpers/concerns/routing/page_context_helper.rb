# frozen_string_literal: true

module Routing
  # Include-only mixin: controller/action predicates for layout, meta, and JSON-LD helpers.
  # Not a public view helper — compose via Layout::AssetRequirementsHelper or StructuredData::JsonLdPageHelper.
  module PageContextHelper
    def chapters_show_page?
      controller_name.to_sym == :chapters && action_name.to_sym == :show
    end

    def tales_show_page?
      controller_name.to_sym == :tales && action_name.to_sym == :show
    end

    def fictions_show_page?
      controller_name.to_sym == :fictions && action_name.to_sym == :show
    end

    def pages_about_page?
      controller_name.to_sym == :pages && action_name.to_sym == :about
    end

    def scanlators_show_page?
      controller_name.to_sym == :scanlators && action_name.to_sym == :show
    end

    def profiles_show_page?
      controller_name.to_sym == :profiles && action_name.to_sym == :show
    end

    def youtube_videos_show_page?
      controller_name.to_sym == :youtube_videos && action_name.to_sym == :show
    end

    def genre_show_page?
      controller_path == 'fictions/genres' && action_name == 'show'
    end

    def bookshelves_show_page?
      controller_name.to_sym == :bookshelves && action_name.to_sym == :show
    end

    def search_index_page?
      controller_name.to_sym == :search && action_name.to_sym == :index
    end

    # App-side Auto ads off on member #show pages; manual slots stay enabled.
    def adsense_auto_ads_excluded_page?
      bookshelves_show_page? ||
        chapters_show_page? ||
        fictions_show_page? ||
        genre_show_page? ||
        tales_show_page? ||
        youtube_videos_show_page?
    end
  end
end
