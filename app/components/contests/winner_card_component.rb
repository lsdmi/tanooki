# frozen_string_literal: true

module Contests
  # Hall-of-fame / results winner card: prize, work, author, contest.
  class WinnerCardComponent < ViewComponent::Base
    include Meta::CoverUrlsHelper

    def initialize(award:, plain: false)
      super()
      @award = award
      @entry = award.contest_entry
      @prize = award.contest_prize
      @fiction = entry.fiction
      @contest = award.contest
      @plain = plain
    end

    private

    attr_reader :award, :entry, :prize, :fiction, :contest, :plain

    def plain? = plain

    def title
      entry.display_title
    end

    def author
      entry.display_author
    end

    def href
      return helpers.fiction_path(fiction) if fiction
      return entry.legacy_url if entry.legacy_url.present?

      helpers.contest_path(contest)
    end
  end
end
