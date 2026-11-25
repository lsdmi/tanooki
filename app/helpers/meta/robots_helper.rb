# frozen_string_literal: true

module Meta
  # `<meta name="robots">`: account pages (sign-in, sign-up, password reset), chapters hidden by a license
  # takedown, and tag-filtered catalog pages stay out of search results.
  module RobotsHelper
    def meta_robots(chapter = nil)
      if devise_controller? || chapter&.license_hidden? || search_results_page? || tag_filtered_catalog_page?
        return 'noindex, follow'
      end

      'max-image-preview:large'
    end

    private

    def search_results_page?
      request.path == search_index_path
    end

    # `/fictions?tags[]=…` is a filtered view of one catalogue, not a page of its own.
    def tag_filtered_catalog_page?
      controller_name == 'fiction_lists' && params[:tags].present?
    end
  end
end
