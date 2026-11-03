# frozen_string_literal: true

module Contests
  # Hall-of-fame / results winner card (prize + work + optional aftermath).
  class WinnerCardComponent < ViewComponent::Base
    include Meta::CoverUrlsHelper

    def initialize(award:, show_aftermath: false)
      super()
      @award = award
      @entry = award.contest_entry
      @prize = award.contest_prize
      @fiction = entry.fiction
      @contest = award.contest
      @show_aftermath = show_aftermath
    end

    private

    attr_reader :award, :entry, :prize, :fiction, :contest, :show_aftermath

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

    def aftermath?
      show_aftermath && fiction.present? && contest.results_published_at.present?
    end

    def chapters_after
      @chapters_after ||= fiction.chapters.released.where(published_at: contest.results_published_at..).count
    end

    def library_count
      @library_count ||= fiction.bookshelf_fictions.count
    end

    def finished?
      fiction.completed_at.present?
    end
  end
end
