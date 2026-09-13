# frozen_string_literal: true

module Fictions
  # Closing navigation tiles on the fictions index (catalog / calendar / library).
  module IndexNavigationHubHelper
    GUEST_LIBRARY_BUTTON_LABEL = 'Увійти до читальні'
    SIGNED_IN_LIBRARY_BUTTON_LABEL = 'Відкрити читальню'
    HUB_BANNER_CLASS = 'fiction-index-hub-banner'
    HUB_CARD_KEYS = %i[storage calendar library].freeze

    HUB_CARD_BASE = {
      storage: {
        title: 'Сховище',
        description: 'Усі твори в єдинім сховку. Поділяйте за жанром, статусом та популярністю.',
        button_label: 'Відкрити сховище',
        button_icon: 'fictions/navigation_hub/storage_button_icon',
        background_image: 'fiction-index-hub-storage.webp'
      },
      calendar: {
        title: 'Календар',
        description: 'Пильнуйте за появою нових розділів, аби не пропустити ані єдиної крихти дивного гомону.',
        button_label: 'Відкрити календар',
        button_icon: 'fictions/navigation_hub/calendar_button_icon',
        background_image: 'fiction-index-hub-calendar.webp'
      },
      library: {
        title: 'Читальня',
        description: 'Тримайте свої мандрівки, таємні книжні дороги та скарби прочитані на єдиній полиці.',
        button_icon: 'fictions/navigation_hub/library_button_icon',
        background_image: 'fiction-index-hub-library.webp'
      }
    }.freeze

    HUB_PROMO_CARD_STYLE = {
      external: false,
      button_variant: :ghost,
      button_size: :md,
      banner_class: HUB_BANNER_CLASS,
      card_class: [
        'group !h-full !min-h-0 !w-full !justify-center !items-start',
        'transition-shadow duration-300 hover:shadow-lg',
        '!rounded-xl !border-0 !px-5 !py-5 !pr-8'
      ].join(' '),
      gradient_class: [
        'bg-gradient-to-r from-slate-950/92 via-slate-950/70 via-[42%] to-slate-950/10',
        'transition-opacity duration-500 group-hover:opacity-100'
      ].join(' '),
      content_class: 'max-w-[15.5rem] w-full items-start text-left',
      content_stack: true,
      content_stack_class: 'gap-1.5',
      title_class: 'text-left text-xl font-bold leading-tight tracking-tight text-white drop-shadow-md',
      description_class: 'text-left text-sm font-normal leading-snug text-white/90 drop-shadow-sm',
      button_class: [
        '!mt-3 !mb-0 !border !border-white/70 !bg-transparent !text-white !rounded-md',
        '!px-3 !py-1.5 !text-sm !font-medium',
        'hover:!border-white hover:!bg-white/10 hover:!text-white',
        'dark:!border-white/70 dark:!bg-transparent dark:!text-white',
        'dark:hover:!border-white dark:hover:!bg-white/10'
      ].join(' '),
      button_stack_class: 'w-fit self-start'
    }.freeze

    HUB_PROMO_BACKGROUND_BASE = [
      'bg-cover bg-no-repeat will-change-transform bg-center',
      'animate-writings-banner-sm sm:animate-writings-banner-md',
      'lg:animate-writings-banner-lg xl:animate-writings-banner-xl',
      'group-hover:[animation-duration:20s] motion-reduce:animate-none motion-reduce:scale-[1.02]'
    ].join(' ')

    HUB_PROMO_BACKGROUND_DELAY = {
      storage: nil,
      calendar: '[animation-delay:-10s]',
      library: '[animation-delay:-20s]'
    }.freeze

    def fiction_index_navigation_hub_cards
      HUB_CARD_KEYS.map { |key| hub_promo_card_for(key) }
    end

    private

    def hub_promo_card_for(key)
      card = HUB_CARD_BASE.fetch(key)

      HUB_PROMO_CARD_STYLE.merge(
        title: card.fetch(:title),
        description: card.fetch(:description),
        href: hub_card_href(key),
        button_label: hub_card_button_label(key, card),
        button_icon: card.fetch(:button_icon),
        background_image: card.fetch(:background_image),
        background_class: [HUB_PROMO_BACKGROUND_BASE, HUB_PROMO_BACKGROUND_DELAY[key]].compact.join(' ')
      )
    end

    def hub_card_href(key)
      case key
      when :storage then alphabetical_fictions_path
      when :calendar then calendar_fictions_path
      when :library then user_signed_in? ? library_path : new_user_session_path
      end
    end

    def hub_card_button_label(key, card)
      return card.fetch(:button_label) unless key == :library

      user_signed_in? ? SIGNED_IN_LIBRARY_BUTTON_LABEL : GUEST_LIBRARY_BUTTON_LABEL
    end
  end
end
