# frozen_string_literal: true

module Ui
  # Five-star display with optional half stars and scanlator-style summary text.
  class StarRatingComponent < ViewComponent::Base
    include StarRatingComponentStyles

    def initialize(rating:, rating_count: nil, show_summary: false)
      super()
      @rating = rating.to_f
      @rating_count = rating_count
      @show_summary = show_summary
    end

    private

    attr_reader :rating, :rating_count, :show_summary

    def show_summary?
      show_summary
    end

    def rated?
      rating.positive?
    end

    def star_states
      (1..5).map do |star|
        if rating >= star
          :full
        elsif rating >= star - 0.5
          :half
        else
          :empty
        end
      end
    end

    def formatted_rating
      helpers.number_with_precision(rating, precision: 1)
    end

    def rating_label
      return 'Рейтинг' unless rated? && rating_count.present?

      "Рейтинг (#{rating_count})"
    end
  end
end
