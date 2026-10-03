# frozen_string_literal: true

module Fictions
  # «Відзнаки та нагороди» (Figma 10089:11784): genre badges where the fiction is in the top 10, best rank first.
  # Genres without badge artwork are skipped; no card when none are left.
  class HonorsCardComponent < ViewComponent::Base
    include AboutCardStyles
    include Fictions::FormattingHelper
    include Layout::TurboDriveHelper

    MAX_BADGES = 4

    def initialize(ranks:)
      super()
      @ranks = ranks
    end

    def render?
      badges.any?
    end

    private

    def badges
      @badges ||= @ranks.filter_map do |genre_name, rank|
        slug = genre_badge_slug(genre_name)
        [genre_name, rank, slug] if badge_asset_available?(slug)
      end.first(MAX_BADGES)
    end

    def rank_classes(rank)
      tone = rank == 1 ? 'bg-red-600' : 'bg-blue-500'
      'token-raw absolute -top-1 -right-1 flex size-6 items-center justify-center rounded-full border-2 border-white ' \
        "#{tone} text-[10px]/4 font-bold text-white"
    end
  end
end
