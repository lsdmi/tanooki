# frozen_string_literal: true

module Contests
  # Derives contest lifecycle phase from timestamps (not a stored status).
  class Phase
    PHASES = %i[
      draft
      announced
      submissions
      judging
      awaiting_results
      results
      cancelled
    ].freeze

    ACTIVE_PHASES = %i[announced submissions judging awaiting_results].freeze
    ARCHIVED_PHASES = %i[results cancelled].freeze

    def initialize(contest, at: Time.current)
      @contest = contest
      @at = at
    end

    def call
      return :cancelled if contest.cancelled_at.present?
      return :draft unless published?
      return :results if contest.results_published_at.present?

      timed_phase
    end

    private

    attr_reader :contest, :at

    def timed_phase
      return :awaiting_results if at >= contest.judging_close_at
      return :judging if at >= contest.submissions_close_at
      return :submissions if at >= contest.submissions_open_at

      at >= contest.announced_at ? :announced : :draft
    end

    def published?
      contest.published_at.present? && contest.published_at <= at
    end
  end
end
