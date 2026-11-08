# frozen_string_literal: true

module Fictions
  # «Відзнаки та нагороди» (Figma 10089:11784): genre badges where the fiction is in the top 10, best rank first.
  # Genres without badge artwork are skipped; no card when none are left.
  class HonorsCardComponent < ViewComponent::Base
    include AboutCardStyles
    include Fictions::FormattingHelper
    include Layout::TurboDriveHelper

    MAX_BADGES = 4
    Badge = Data.define(:label, :rank, :slug, :href)

    def initialize(ranks:, fiction: nil, user: nil)
      super()
      @ranks = ranks
      @fiction = fiction
      @user = user
    end

    def render?
      badges.any?
    end

    private

    def badges
      @badges ||= (contest_badges + genre_badges).first(MAX_BADGES)
    end

    def contest_badges
      return [] unless @fiction && Contests::PublicAccess.surfaces_visible?(@user)

      Contests::PlaceBadges.new(@fiction).call.map do |badge|
        Badge.new(label: badge.label, rank: badge.place, slug: badge.slug, href: badge.href)
      end
    end

    def genre_badges
      @ranks.filter_map do |genre_name, rank|
        slug = genre_badge_slug(genre_name)
        next unless badge_asset_available?(slug)

        Badge.new(label: genre_name, rank:, slug:, href: helpers.fiction_genre_fictions_path(slug))
      end
    end

    def rank_classes(rank)
      # blue-500 + white ≈ 3.7:1; blue-700 / red-700 clear WCAG AA (≥ 4.5:1) for the #rank chip.
      tone = rank == 1 ? 'bg-red-700' : 'bg-blue-700'
      'token-raw absolute -top-1 -right-1 flex size-6 items-center justify-center rounded-full border-2 border-white ' \
        "#{tone} text-[10px]/4 font-bold text-white"
    end
  end
end
