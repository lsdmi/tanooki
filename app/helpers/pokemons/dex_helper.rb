# frozen_string_literal: true

module Pokemons
  # Dex leaderboard rank labels, battle result badges and training/battle cooldown copy for the dex UI.
  module DexHelper
    RESULT_BADGE = 'inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs/4 font-semibold ring-1 ring-inset'
    RESULT_WON = 'bg-status-success-subtle-bg text-status-success-subtle-fg ring-status-success-subtle-border'
    RESULT_LOST = 'bg-status-danger-subtle-bg text-status-danger-subtle-fg ring-status-danger-subtle-border'
    # Lucide «trophy».
    TROPHY_PATHS = [
      'M6 9H4.5a2.5 2.5 0 0 1 0-5H6', 'M18 9h1.5a2.5 2.5 0 0 0 0-5H18', 'M4 22h16',
      'M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22',
      'M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22', 'M18 2H6v7a6 6 0 0 0 12 0V2Z'
    ].freeze
    # Lucide «shield-x».
    SHIELD_X_PATHS = [
      'M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 ' \
      '6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z',
      'm14.5 9.5-5 5', 'm9.5 9.5 5 5'
    ].freeze
    ICON_STROKE = {
      stroke: 'currentColor', 'stroke-width': 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round'
    }.freeze
    # The lowest percentile of each title in pokemons.titles: bands narrow towards the top, «Чемпіон» is the top 1%.
    TITLE_PERCENTILES = [0, 0.15, 0.30, 0.45, 0.58, 0.70, 0.80, 0.87, 0.92, 0.955, 0.975, 0.99].freeze

    def training_cooldown?(user)
      user.trainer_profile.training_on_cooldown?
    end

    def training_cooldown_reason(user)
      cooldown_message_for(user.trainer_profile.last_training_at, Balance::TRAINING_COOLDOWN)
    end

    def reason_for_cooldown(current_user)
      cooldown_message_for(current_user.trainer_profile.last_battle_at || 1.year.ago, Balance::BATTLE_COOLDOWN)
    end

    def trainer_caption(user, dex_leaderboard)
      "#{dex_title(dex_leaderboard.percentile_for(user))} ##{dex_leaderboard.rank_for(user)}"
    end

    # «Перемога» / «Поразка» with a trophy or a crossed shield, so the result does not rest on colour alone.
    def battle_result_badge(won)
      tag.span(class: "#{RESULT_BADGE} #{won ? RESULT_WON : RESULT_LOST}") do
        safe_join([battle_result_icon(won), won ? 'Перемога' : 'Поразка'])
      end
    end

    # +percentile+ from DexLeaderboard#percentile_for; nil (no battles yet) gets the first title.
    def dex_title(percentile)
      t('pokemons.titles')[TITLE_PERCENTILES.rindex { |from| from <= percentile.to_f }]
    end

    private

    def battle_result_icon(won)
      lucide_icon(won ? TROPHY_PATHS : SHIELD_X_PATHS, 'size-3.5')
    end

    def lucide_icon(paths, size)
      tag.svg(safe_join(paths.map { |d| tag.path(d:) }),
              class: size, viewBox: '0 0 24 24', fill: 'none', aria: { hidden: true }, **ICON_STROKE)
    end

    def cooldown_message_for(time, cooldown)
      remaining_minutes = ((cooldown.to_i - (Time.current - time)) / 1.minute).floor
      remaining_minutes = cooldown.in_minutes.to_i if remaining_minutes.negative?

      "#{remaining_minutes} хв"
    end
  end
end
