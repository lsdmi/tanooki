# frozen_string_literal: true

module Chapters
  # No ads around the text of a licensed work.
  module ReaderAds
    extend ActiveSupport::Concern

    private

    def adsense_allowed?
      return false if @chapter&.fiction&.licensed?

      super
    end
  end
end
