# frozen_string_literal: true

module Contests
  # Archive list card: contest cover, title as text, type, dates, entry count, top covers.
  class ArchiveCardComponent < ViewComponent::Base
    include Meta::CoverUrlsHelper

    def initialize(contest:, entry_count: 0, top_covers: [])
      super()
      @contest = contest
      @entry_count = entry_count
      @top_covers = Array(top_covers)
    end

    private

    attr_reader :contest, :entry_count, :top_covers

    def date_range
      open = l(contest.submissions_open_at.to_date)
      close = l(contest.submissions_close_at.to_date)
      "#{open} – #{close}"
    end

    def kind_label
      t("contests.kinds.#{contest.kind}")
    end
  end
end
