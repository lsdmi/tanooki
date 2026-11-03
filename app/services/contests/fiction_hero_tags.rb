# frozen_string_literal: true

module Contests
  # Editorial tags for a fiction hero: participant / winner linked to the contest.
  class FictionHeroTags
    Tag = Data.define(:kind, :label, :href)

    VISIBLE_STATUSES = %w[accepted qualified incomplete disqualified].freeze
    MAX = 2

    def initialize(fiction)
      @fiction = fiction
    end

    def call
      return [] if fiction.blank?

      tags = visible_entries.filter_map { |entry| tag_for(entry) }
      tags.sort_by { |tag| tag.kind == :contest_winner ? 0 : 1 }.first(MAX)
    end

    private

    attr_reader :fiction

    def visible_entries
      fiction.contest_entries
             .joins(:contest)
             .merge(Contest.visible)
             .includes(:contest, awards: :contest_prize)
             .where(status: VISIBLE_STATUSES)
             .order(submitted_at: :desc)
             .to_a
    end

    def tag_for(entry)
      contest = entry.contest
      kind, label = kind_and_label(entry, contest)
      Tag.new(kind:, label:, href: Rails.application.routes.url_helpers.contest_path(contest))
    end

    def kind_and_label(entry, contest)
      award = winning_award(entry)
      return [:contest_winner, winner_label(award, contest)] if award

      [:contest_entry, I18n.t('contests.tags.entry', contest: contest.title)]
    end

    def winning_award(entry)
      entry.awards.find { |award| award.contest_prize.place? || award.contest_prize.nomination? }
    end

    def winner_label(award, contest)
      place = award.contest_prize.title
      I18n.t('contests.tags.winner', place:, contest: contest.title)
    end
  end
end
