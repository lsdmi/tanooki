# frozen_string_literal: true

module Contests
  # Static sections of the publish-time rules snapshot (dates, scoring, prizes, how to join).
  module RulesBlocks
    private

    def dates_block
      {
        'announced_at' => contest.announced_at.iso8601,
        'submissions_open_at' => contest.submissions_open_at.iso8601,
        'submissions_close_at' => contest.submissions_close_at.iso8601,
        'judging_close_at' => contest.judging_close_at.iso8601
      }
    end

    def scoring_block
      {
        'jury_weight' => contest.jury_weight,
        'readers_weight' => 100 - contest.jury_weight,
        'criteria' => Array(contest.criteria)
      }
    end

    def prizes_block
      contest.prizes.order(:position, :id).map do |prize|
        {
          'title' => prize.title,
          'kind' => prize.kind,
          'place' => prize.place,
          'cash_uah' => prize.cash_uah,
          'unlock_at_uah' => prize.unlock_at_uah,
          'perks' => prize.perks
        }
      end
    end

    def how_to_join_lines
      %w[step1_title step1_body step2_title step2_body step3_title step3_body].map do |key|
        I18n.t("contests.show.how_to_join.#{key}")
      end
    end
  end
end
