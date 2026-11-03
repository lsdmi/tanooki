# frozen_string_literal: true

module Contests
  # Prizes list plus donation progress toward unlock goals.
  class PrizePoolComponent < ViewComponent::Base
    def initialize(presenter:)
      super()
      @presenter = presenter
      @contest = presenter.contest
    end

    private

    attr_reader :presenter, :contest

    def prizes
      @prizes ||= contest.prizes.order(:position, :id).to_a
    end

    def total
      presenter.prize_pool_total
    end

    def guaranteed
      contest.prize_pool_uah + contest.carryover_uah
    end

    def donations
      contest.donations_uah
    end

    def goals
      presenter.donation_goals
    end

    def progress_percent
      ceiling = goals.map(&:unlock_at_uah).max || [guaranteed, 1].max
      ((total.to_f / ceiling) * 100).clamp(0, 100).round
    end

    def money(amount)
      "#{helpers.number_with_delimiter(amount, delimiter: ' ')} ₴"
    end
  end
end
