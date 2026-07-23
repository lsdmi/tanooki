# frozen_string_literal: true

require 'test_helper'

module Root
  class PrefooterHelperTest < ActionView::TestCase
    include ExternalUrls::UrlsHelper
    include PrefooterHelper

    test 'home_videos_grid_promos include community and buymeacoffee cards' do
      assert_equal %i[community buymeacoffee], home_videos_grid_promos
    end

    test 'home_videos_grid_promo_card returns telegram card locals' do
      card = home_videos_grid_promo_card(:community)
      expected = {
        banner_class: 'community-banner',
        title: 'Telegram-спільнота',
        button_label: 'Telegram-канал',
        href: telegram_site_url,
        visual: 'root/prefooter/promo/telegram_visual'
      }

      assert_equal expected, card.slice(*expected.keys)
    end

    test 'home_videos_grid_promo_card returns buymeacoffee card locals' do
      card = home_videos_grid_promo_card(:buymeacoffee)
      expected = {
        banner_class: 'buymeacoffee-banner',
        title: 'Підтримайте Баку',
        button_label: 'Buy Me a Coffee',
        href: buymeacoffee_site_url
      }

      assert_equal expected, card.slice(*expected.keys)
      assert_not card.key?(:visual)
    end
  end
end
