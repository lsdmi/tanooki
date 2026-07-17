# frozen_string_literal: true

module Adsense
  # Shared AdSense placement helpers for browse pages and the chapter reader.
  module PlacementsHelper
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
      Adsense::HOME_VIDEOS_GRID_PLACEMENTS.keys.any? { |placement| adsense_slot_renderable?(placement) }
    end
  end
end
