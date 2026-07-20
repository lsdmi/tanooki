# frozen_string_literal: true

module Adsense
  # Shared AdSense placement helpers for browse pages and the chapter reader.
  module PlacementsHelper
    # 2×2 homepage grid below «Популярні Відео»: two AdSense cells + two promo cards.
    HOME_VIDEOS_GRID_CELLS = [
      { kind: :ad, placement: :home_videos_grid_top_left, navigation_key: 'home-videos-tl' },
      { kind: :ad, placement: :home_videos_grid_top_right, navigation_key: 'home-videos-tr' },
      { kind: :promo, promo: :community },
      { kind: :promo, promo: :buymeacoffee }
    ].freeze

    def adsense_client_id
      Adsense::CLIENT
    end

    def adsense_slot_id(placement)
      Adsense::SLOTS[placement.to_sym]
    end

    def adsense_slot_live?(placement)
      adsense_allowed? && adsense_slot_id(placement).present?
    end

    def adsense_slot_development_preview?
      Rails.env.development?
    end

    def adsense_slot_renderable?(placement)
      adsense_slot_live?(placement) || adsense_slot_development_preview?
    end

    def adsense_adblock_check?
      adsense_allowed? || adsense_slot_development_preview?
    end

    def adsense_home_banners_renderable?
      Adsense::HOME_BANNER_PLACEMENTS.keys.any? { |placement| adsense_slot_renderable?(placement) }
    end

    def adsense_home_videos_grid_renderable?
      adsense_home_videos_grid_ad_placements.keys.any? { |placement| adsense_slot_renderable?(placement) }
    end

    def adsense_home_videos_grid_cells
      HOME_VIDEOS_GRID_CELLS
    end

    def adsense_home_videos_grid_ad_placements
      HOME_VIDEOS_GRID_CELLS
        .select { |cell| cell[:kind] == :ad }
        .to_h { |cell| [cell[:placement], cell[:navigation_key]] }
    end
  end
end
