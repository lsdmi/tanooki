# frozen_string_literal: true

module Layout
  # Controller/action predicates for layout assets and page-specific UI.
  module PageContextHelper
    def chapters_show_page?
      controller_name.to_sym == :chapters && action_name.to_sym == :show
    end

    def chapters_show_referer?
      request.referer&.include?('chapters') && controller_name.to_sym == :comments
    end

    def requires_font?
      (controller_name.to_sym == :tales && action_name.to_sym == :show) ||
        chapters_show_page?
    end

    def requires_tinymce?
      (controller_name == 'publications' && %w[new edit create update].include?(action_name)) ||
        (controller_name == 'chapters' && %w[new edit create update].include?(action_name))
    end

    def requires_sweetalert?
      controller_name.in?(%w[studio readings])
    end

    def genre_show_page?
      controller_path == 'fictions/genres' && action_name == 'show'
    end
  end
end
