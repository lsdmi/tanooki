# frozen_string_literal: true

# Google AdSense unit configuration.
module Adsense
  CLIENT = ENV.fetch('ADSENSE_CLIENT', 'ca-pub-5596031369567303').freeze

  SLOTS = {
    chapter_reader_top: ENV['ADSENSE_CHAPTER_READER_TOP_SLOT'].presence,
    chapter_reader_bottom: ENV['ADSENSE_CHAPTER_READER_BOTTOM_SLOT'].presence,
    fiction_alphabetical: ENV['ADSENSE_FICTION_ALPHABETICAL_SLOT'].presence,
    bookshelf: ENV['ADSENSE_BOOKSHELF_SLOT'].presence,
    home_banner_left: ENV['ADSENSE_HOME_BANNER_LEFT_SLOT'].presence,
    home_banner_right: ENV['ADSENSE_HOME_BANNER_RIGHT_SLOT'].presence
  }.freeze

  CHAPTER_READER_SLOTS = {
    top: SLOTS[:chapter_reader_top],
    bottom: SLOTS[:chapter_reader_bottom]
  }.freeze

  # Up to six slot IDs for the auto-closing reader ad drawer (comma-separated).
  DRAWER_SLOTS = ENV['ADSENSE_CHAPTER_READER_DRAWER_SLOTS'].to_s.split(',').map(&:strip).reject(&:empty?).freeze
end
