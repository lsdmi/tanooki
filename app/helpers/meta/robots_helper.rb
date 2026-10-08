# frozen_string_literal: true

module Meta
  # `<meta name="robots">`: account pages (sign-in, sign-up, password reset) and chapters hidden by a license
  # takedown stay out of search results.
  module RobotsHelper
    def meta_robots(chapter = nil)
      return 'noindex, follow' if devise_controller? || chapter&.license_hidden?

      'max-image-preview:large'
    end
  end
end
