# frozen_string_literal: true

module Contests
  # Prizes list plus donation progress toward unlock goals.
  class PrizePoolComponent < ViewComponent::Base
    include Ui::StrokeIconHelper

    def initialize(presenter:, embedded: false)
      super()
      @presenter = presenter
      @contest = presenter.contest
      @embedded = embedded
    end

    private

    attr_reader :presenter, :contest, :embedded

    def embedded? = embedded

    def prizes
      @prizes ||= contest.prizes.order(:position, :id).to_a
    end

    def paid_prizes
      prizes.select { |prize| prize.cash_uah.positive? }
    end

    def honorary_groups
      prizes.reject { |prize| prize.cash_uah.positive? }.slice_when { |left, right| left.perks != right.perks }.to_a
    end

    def honorary_label(group)
      numbers = place_numbers(group)
      return joined_titles(group) unless ranged_places?(group, numbers)

      t('contests.show.prizes.places_range', from: numbers.first, to: numbers.last)
    end

    def place_numbers(group)
      group.filter_map { |prize| prize.place if prize.place? }.sort
    end

    def ranged_places?(group, numbers)
      numbers.size == group.size && numbers.many? && consecutive_places?(numbers)
    end

    def consecutive_places?(numbers)
      numbers.each_cons(2).all? { |left, right| right == left + 1 }
    end

    def joined_titles(group)
      group.map(&:title).join(', ')
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

    def pool_breakdown
      parts = [t('contests.show.prizes.guaranteed', amount: money(guaranteed))]
      parts << t('contests.show.prizes.donations', amount: money(donations)) if donations.positive?
      parts.join(' · ')
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
