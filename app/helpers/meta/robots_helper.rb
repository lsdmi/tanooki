# frozen_string_literal: true

module Meta
  # `<meta name="robots">`: account pages (sign-in, sign-up, password reset) stay out of search results.
  module RobotsHelper
    def meta_robots
      devise_controller? ? 'noindex, follow' : 'max-image-preview:large'
    end
  end
end
