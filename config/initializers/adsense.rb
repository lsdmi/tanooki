# frozen_string_literal: true

# Google AdSense unit configuration (chapter reader in-content slots).
module Adsense
  CLIENT = ENV.fetch('ADSENSE_CLIENT', 'ca-pub-5596031369567303').freeze

  CHAPTER_READER_SLOTS = {
    top: ENV['ADSENSE_CHAPTER_READER_TOP_SLOT'].presence,
    bottom: ENV['ADSENSE_CHAPTER_READER_BOTTOM_SLOT'].presence
  }.freeze

  # Up to six slot IDs for the auto-closing reader ad drawer (comma-separated).
  DRAWER_SLOTS = ENV['ADSENSE_CHAPTER_READER_DRAWER_SLOTS'].to_s.split(',').map(&:strip).reject(&:empty?).freeze
end
