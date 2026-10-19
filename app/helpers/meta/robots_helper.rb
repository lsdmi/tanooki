# frozen_string_literal: true

module Meta
  # `<meta name="robots">`: account pages (sign-in, sign-up, password reset) and chapters hidden by a license
  # takedown stay out of search results.
  module RobotsHelper
    def meta_robots(chapter = nil)
      return 'noindex, follow' if devise_controller? || chapter&.license_hidden? || search_results_page?

      'max-image-preview:large'
    end

    private

    def search_results_page?
      request.path == search_index_path
    end
  end
end
