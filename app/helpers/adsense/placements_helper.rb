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
  end
end
