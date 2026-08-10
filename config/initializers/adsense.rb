# frozen_string_literal: true

# Google AdSense unit configuration.
# Slot IDs are public (rendered in data-ad-slot); edit here when units change in AdSense UI.
module Adsense
  CLIENT = 'ca-pub-5596031369567303'

  SLOTS = {
    chapter_reader_top: '9495090525',
    chapter_reader_bottom: '1793380233',
    fiction_alphabetical: '4717940366',
    bookshelf: '9153677690',
    home_banner_left: '7705289689',
    home_banner_right: '6392208016',
    youtube_video: '2144220675',
    youtube_index: '4709643993',
    translation_requests_sidebar: '6536785460',
    translation_requests_top: '8125199307',
    tales_index: '4488020825',
    tales_show: '2108203838',
    search_index: '9203079892',
    fictions_index_top: '1743214661',
    fictions_index_mid: '6887464203',
    genres_show_top: '1140503454',
    genres_show_mid: '3963656072',
    fiction_show: '8311601798',
    fiction_show_sidebar: '8551274943'
  }.freeze

  HOME_BANNER_PLACEMENTS = {
    home_banner_left: 'home-mid-left',
    home_banner_right: 'home-mid-right'
  }.freeze

  CHAPTER_READER_SLOTS = {
    top: SLOTS[:chapter_reader_top],
    bottom: SLOTS[:chapter_reader_bottom]
  }.freeze

  # Up to six slot IDs for the auto-closing reader ad drawer; cycles when fewer than six.
  DRAWER_SLOTS = %w[
    3925855020
  ].freeze
end
