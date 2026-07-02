# frozen_string_literal: true

module Root
  # Picks one hero banner pair for everyone and rotates it daily via Rails.cache.
  # Preview any variant with ?banner=husky_1 (also husky_2, mstv) on the home page.
  class HeroBanner
    MOBILE_WIDTH = 1474
    MOBILE_HEIGHT = 1407
    MOBILE_WIDE_WIDTH = 1474
    MOBILE_WIDE_HEIGHT = 936

    SETS = [
      {
        key: 'default',
        desktop: 'banner/banner_desktop.webp',
        mobile: 'banner/banner_mobile_tall.webp'
      },
      {
        key: 'husky_1',
        desktop: 'banner/banner_desktop_husky_1.webp',
        mobile: 'banner/banner_mobile_tall_husky_1.webp'
      },
      {
        key: 'husky_2',
        desktop: 'banner/banner_desktop_husky_2.webp',
        mobile: 'banner/banner_mobile_tall_husky_2.webp'
      },
      {
        key: 'mstv',
        desktop: 'banner/banner_desktop_mstv.webp',
        mobile: 'banner/banner_mobile_tall_mstv.webp'
      }
    ].freeze

    CACHE_KEY_PREFIX = 'hero_banner/v1'
    ROTATION_PERIOD = 1.day

    def self.current(preview_key: nil)
      new(preview_key:).current
    end

    def self.cache_key_for(date = Time.zone.today)
      "#{CACHE_KEY_PREFIX}/#{date}"
    end

    def initialize(preview_key: nil)
      @preview_key = preview_key
    end

    def current
      set = if @preview_key.present? && find_set(@preview_key)
              find_set(@preview_key)
            else
              find_set!(daily_key)
            end

      set.merge(mobile_wide: mobile_wide_for(set[:key]))
    end

    def self.mobile_wide_for(key)
      return 'banner/banner_mobile_wide.webp' if key == 'default'

      "banner/banner_mobile_wide_#{key}.webp"
    end

    private

    def mobile_wide_for(key)
      self.class.mobile_wide_for(key)
    end

    def daily_key
      Rails.cache.fetch(self.class.cache_key_for, expires_in: ROTATION_PERIOD) do
        SETS.sample[:key]
      end
    end

    def find_set(key)
      SETS.find { |entry| entry[:key] == key }
    end

    def find_set!(key)
      find_set(key) || SETS.first
    end
  end
end
