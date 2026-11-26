# frozen_string_literal: true

module Fictions
  module Reviews
    # The mark on a review: «Відгук», the author's rating as stars, and how many chapters they read. A review always
    # has a rating (Eligibility), so the stars are only missing if the rating was removed afterwards.
    class BadgeComponent < ViewComponent::Base
      include Ui::StrokeIconHelper

      STAR_ON = 'fill-amber-400 text-amber-400'
      STAR_OFF = 'fill-transparent text-amber-400'

      def initialize(rating:, read_count:)
        super()
        @rating = rating
        @read_count = read_count
      end

      private

      attr_reader :rating, :read_count

      def read_text
        return t('fictions.reviews.read_count', count: read_count) if read_count.positive?

        t('fictions.reviews.read_none')
      end

      def star_classes(star)
        "size-3.5 #{star <= rating.to_i ? STAR_ON : STAR_OFF}"
      end
    end
  end
end
