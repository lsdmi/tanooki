# frozen_string_literal: true

# Google AdSense units (chapter reader and shared client id).
module AdsenseHelper
  def adsense_client_id
    Adsense::CLIENT
  end

  def chapter_reader_ad_slot(placement)
    slot = Adsense::CHAPTER_READER_SLOTS.fetch(placement.to_sym)
    slot.presence || Adsense::CHAPTER_READER_SLOTS[:top]
  end

  def chapter_reader_ad_live?(placement)
    adsense_allowed? && chapter_reader_ad_slot(placement).present?
  end

  def chapter_reader_ad_drawer_live?
    adsense_allowed? && Adsense::DRAWER_SLOTS.any?
  end

  DRAWER_MAX_SLOTS = 6

  def chapter_reader_ad_drawer_slots
    slots = Adsense::DRAWER_SLOTS
    return [] if slots.empty?

    Array.new(DRAWER_MAX_SLOTS) { |i| slots[i % slots.length] }
  end
end
