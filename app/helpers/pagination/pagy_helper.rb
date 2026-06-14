# frozen_string_literal: true

module Pagination
  # Pagy view helpers (pagy_url_for, etc.) for all pages after TurboNavHelper removal.
  module PagyHelper
    include Pagy::Frontend

    def pagy_next_page_src(pagy)
      pagy_url_for(pagy, pagy.next)
    end
  end
end
