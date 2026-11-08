# frozen_string_literal: true

module Contests
  # Top-five place awards that have contest badge artwork. The fiction honors row shows these
  # instead of the amber winner pill.
  class PlaceBadges
    TOP = (1..5)
    Result = Data.define(:label, :place, :slug, :href)

    def initialize(fiction)
      @fiction = fiction
    end

    def call
      return [] if fiction.blank?

      awards.filter_map { |award| result_for(award) }
    end

    def self.replaces_tag?(award)
      return false unless award

      prize = award.contest_prize
      prize.place? && TOP.cover?(prize.place.to_i) && asset?(award.contest.slug)
    end

    def self.asset?(slug)
      return false if slug.blank?

      Rails.application.assets.load_path.find("badges/thumbs/#{slug}.webp").present?
    end

    private

    attr_reader :fiction

    def awards
      ContestAward.joins(:contest_entry, :contest_prize)
                  .merge(Contests::PublicAccess.discoverable_contests)
                  .where(contest_entries: { fiction_id: fiction.id, status: FictionHeroTags::VISIBLE_STATUSES })
                  .where(contest_prizes: { kind: :place, place: TOP })
                  .includes(:contest, :contest_prize)
                  .order('contest_prizes.place ASC, contest_awards.id ASC')
    end

    def result_for(award)
      return unless self.class.replaces_tag?(award)

      contest = award.contest
      Result.new(
        label: contest.title,
        place: award.contest_prize.place,
        slug: contest.slug,
        href: Rails.application.routes.url_helpers.contest_path(contest)
      )
    end
  end
end
