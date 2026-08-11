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

    def calendar_ad_slots
      slots = Adsense::CALENDAR_SLOTS
      return [] if slots.empty?

      slots.filter_map(&:presence)
    end

    def calendar_ad_slot_for(insert_index)
      slots = calendar_ad_slots
      return if slots.empty?

      slots[insert_index % slots.length]
    end

    def calendar_adsense_live?
      adsense_allowed? && Adsense::CALENDAR_SLOTS.any?
    end

    def calendar_adsense_renderable?
      calendar_adsense_live? || adsense_slot_development_preview?
    end

    def adsense_inline_slot_renderable?(slot_id:, placement: nil)
      return adsense_slot_renderable?(placement) if slot_id.blank?

      adsense_slot_development_preview? || (adsense_allowed? && slot_id.present?)
    end

    def adsense_inline_slot_live?(slot_id:)
      adsense_allowed? && slot_id.present?
    end
  end
end
