# frozen_string_literal: true

module Fictions
  # «Якість перекладу» (Figma 10089:11997): the average, five stars and the rating count. Signed-in readers rate with
  # the stars (rating_controller.js), which show their own rating; guests see the average and a login prompt.
  class RatingCardComponent < ViewComponent::Base
    include AboutCardStyles
    include Ui::StrokeIconHelper

    STAR_ON = 'fill-amber-400 text-amber-400'
    STAR_OFF = 'fill-transparent text-amber-400'

    def initialize(fiction:, user:, heading_id: 'fiction-rating-title')
      super()
      @fiction = fiction
      @user = user
      @heading_id = heading_id
    end

    private

    attr_reader :fiction, :user, :heading_id

    def summary
      @summary ||= fiction.rating_summary
    end

    def average_text
      count, average = summary
      count.zero? ? '—' : format('%.1f', average)
    end

    def summary_text
      t('fictions.about.rating.summary', ratings: t('fictions.hero.stats.ratings', count: summary.first))
    end

    def filled_stars
      user ? fiction.user_rating(user).to_i : summary.last.round
    end

    def star_classes(star)
      "size-5 md:size-6 #{star <= filled_stars ? STAR_ON : STAR_OFF}"
    end

    def login_path
      new_user_session_path(return_to: fiction_path(fiction))
    end
  end
end
