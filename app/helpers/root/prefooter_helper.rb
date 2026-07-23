# frozen_string_literal: true

module Root
  # Homepage prefooter promo cards below «Популярні Відео».
  module PrefooterHelper
    include ExternalUrls::UrlsHelper

    HOME_VIDEOS_GRID_PROMOS = %i[community buymeacoffee].freeze

    HOME_VIDEOS_GRID_PROMO_CARDS = {
      community: {
        banner_class: 'community-banner',
        title: 'Telegram-спільнота',
        description: 'Обговорюйте улюблені ранобе, діліться враженнями та знаходьте нових друзів.',
        button_label: 'Telegram-канал',
        background_image: 'psyduck_background.webp',
        button_icon: 'root/prefooter/promo/telegram_button_icon',
        visual: 'root/prefooter/promo/telegram_visual'
      },
      buymeacoffee: {
        banner_class: 'buymeacoffee-banner',
        title: 'Підтримайте Баку',
        description: 'Поміч на утримання серверів, розвиток сайту, конкурси та донати на ЗСУ.',
        button_label: 'Buy Me a Coffee',
        background_image: 'modal-bg.webp',
        button_icon: 'root/prefooter/promo/buymeacoffee_button_icon'
      }
    }.freeze

    def home_videos_grid_promos
      HOME_VIDEOS_GRID_PROMOS
    end

    def home_videos_grid_promo_card(promo)
      config = HOME_VIDEOS_GRID_PROMO_CARDS.fetch(promo)
      href = promo == :community ? telegram_site_url : buymeacoffee_site_url

      config.merge(href:)
    end
  end
end
