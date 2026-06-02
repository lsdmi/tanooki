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
end
