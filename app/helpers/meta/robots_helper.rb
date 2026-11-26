# frozen_string_literal: true

module Meta
  # `<meta name="robots">`: account pages (sign-in, sign-up, password reset), chapters hidden by a license
  # takedown, and every catalog view with a query string (filters, sort, pages) stay out of search results.
  # Their canonical is the bare catalog, so search keeps one page for the catalogue.
  module RobotsHelper
    def meta_robots(chapter = nil)
      if devise_controller? || chapter&.license_hidden? || search_results_page? || filtered_catalog_page?
        return 'noindex, follow'
      end

      'max-image-preview:large'
    end

    private

    def search_results_page?
      request.path == search_index_path
    end

    # `/fictions/alphabetical?…` with any filter, sort or page is a variant of the one catalogue, not a page of its own.
    def filtered_catalog_page?
      controller_name == 'fiction_lists' && request.query_parameters.any?
    end
  end
end
