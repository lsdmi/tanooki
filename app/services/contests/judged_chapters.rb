# frozen_string_literal: true

module Contests
  # Released chapters that count toward contest volume (deadline / in-window scope).
  class JudgedChapters
    def self.call(contest:, fiction:) = new(contest:, fiction:).call

    def initialize(contest:, fiction:)
      @contest = contest
      @fiction = fiction
    end

    def call
      return Chapter.none if fiction.blank?

      scope = fiction.chapters.released
                     .where("#{Chapter::PUBLIC_TIME_SQL} <= ?", contest.submissions_close_at)
      scope = scope.where("#{Chapter::PUBLIC_TIME_SQL} >= ?", contest.submissions_open_at) if contest.in_window?
      scope.order(:id)
    end

    private

    attr_reader :contest, :fiction
  end
end
