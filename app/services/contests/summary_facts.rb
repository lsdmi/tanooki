# frozen_string_literal: true

module Contests
  # The six "at a glance" facts of a contest, built only from contest fields.
  class SummaryFacts
    LABELS = {
      deadline: 'Дедлайн', fee: 'Внесок', first_prize: 'Перший приз', who: 'Хто може',
      what: 'Що подавати', genre_rating: 'Жанр і маркування'
    }.freeze
    KIND_VALUES = {
      'original' => 'ориджинал', 'fanfiction' => 'фанфік', 'translation' => 'переклад', 'art' => 'арт'
    }.freeze

    def initialize(contest, prize_pool_total:)
      @contest = contest
      @prize_pool_total = prize_pool_total
    end

    # [{ key:, label:, value: }] in display order.
    def call
      values.map { |key, value| { key:, label: translate("facts.#{key}", LABELS.fetch(key)), value: } }
    end

    private

    attr_reader :contest, :prize_pool_total

    def values
      {
        deadline: I18n.l(contest.submissions_close_at.to_date),
        fee: translate('facts.fee_value', 'безкоштовно'),
        first_prize: first_prize,
        who: translate('facts.who_value', 'зареєстровані з підтвердженою поштою'),
        what: what,
        genre_rating: genre_rating
      }
    end

    def first_prize
      prize = contest.prizes.place.order(:place, :position).first
      pool = money(prize_pool_total)
      return "фонд #{pool}" if prize.nil? || prize.cash_uah.zero?

      "#{money(prize.cash_uah)} (фонд #{pool})"
    end

    def what
      kind = [('новий' if contest.requires_new_work?), KIND_VALUES.fetch(contest.kind, contest.kind)].compact
      [kind.join(' '), *volume_parts].join(' · ')
    end

    def volume_parts
      [("від #{delimited(contest.min_words)} слів" if contest.min_words),
       ("не менше #{contest.min_chapters} розділів" if contest.min_chapters)].compact
    end

    def genre_rating
      rating = contest.max_content_rating.to_i
      [contest.required_genre&.name, rating.zero? ? 'для всіх' : "до #{rating}+"].compact.join(' · ')
    end

    def money(amount)
      "#{delimited(amount)} ₴"
    end

    def delimited(number)
      ActiveSupport::NumberHelper.number_to_delimited(number, delimiter: ' ')
    end

    def translate(key, default)
      I18n.t("contests.show.#{key}", default:)
    end
  end
end
