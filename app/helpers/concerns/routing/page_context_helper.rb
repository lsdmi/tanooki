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
  end
end
