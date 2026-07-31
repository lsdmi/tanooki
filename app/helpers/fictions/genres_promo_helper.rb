# frozen_string_literal: true

module Fictions
  # Static promo card on genre hub pages (replaces legacy hero ad banner).
  module GenresPromoHelper
    WRITINGS_PROMO_DESCRIPTION =
      'Завантажуй власну роботу чи переклад — історії, ранобе чи фанфіки. ' \
      'Публікуй в писальні та ділись ними зі спільнотою.'
    WRITINGS_PROMO_DESCRIPTION_SHORT =
      'Завантажуй власну роботу чи переклад — історії, ранобе чи фанфіки.'

    GUEST_PROMO_BUTTON_LABEL = 'Увійти та почати писати'
    SIGNED_IN_PROMO_BUTTON_LABEL = 'Відкрити писальню'

    FICTION_GENRE_PROMO_CARD = {
      banner_class: 'fiction-genre-writings-banner',
      title: 'Твори із Бакою',
      description: WRITINGS_PROMO_DESCRIPTION,
      description_short: WRITINGS_PROMO_DESCRIPTION_SHORT,
      description_short_class: 'xl:hidden',
      description_full_class: 'hidden xl:inline',
      badge_label: 'Для авторів',
      badge_icon: 'fictions/genres/promo/authors_badge_icon',
      background_image: 'fiction-genre-writings-promo.webp',
      button_icon: 'fictions/genres/promo/writings_button_icon',
      external: false,
      card_class: [
        'group !justify-center border border-cyan-700 dark:border-rose-700',
        'transition-shadow duration-300 hover:shadow-lg',
        'max-lg:!rounded-lg',
        '!px-4 !py-6 md:!px-6 md:!py-8',
        'lg:min-h-[10.5rem] lg:!rounded-xl lg:!pl-8 lg:!pr-7 lg:!py-5',
        'xl:min-h-[11rem] xl:!pl-9 xl:!pr-8 xl:!py-6'
      ].join(' '),
      background_class: [
        'bg-cover bg-no-repeat will-change-transform',
        'bg-[center_42%] sm:bg-[62%_44%] md:bg-[68%_45%] lg:bg-[72%_43%] xl:bg-[75%_40%]',
        'animate-writings-banner-sm sm:animate-writings-banner-md',
        'lg:animate-writings-banner-lg xl:animate-writings-banner-xl',
        'group-hover:[animation-duration:20s] motion-reduce:animate-none motion-reduce:scale-[1.02]'
      ].join(' '),
      gradient_class: [
        'bg-gradient-to-t from-slate-950/95 via-slate-900/80 to-slate-900/25',
        'sm:bg-gradient-to-tr sm:from-slate-950/95 sm:via-slate-900/80 sm:to-slate-900/20',
        'md:bg-gradient-to-r md:from-slate-950/95 md:via-slate-900/85 md:via-[62%] md:to-slate-900/10',
        'lg:via-[58%] xl:via-[55%]',
        'transition-opacity duration-500 group-hover:opacity-100'
      ].join(' '),
      badge_class: [
        '!hidden md:!inline-flex !self-center lg:!self-start border border-white',
        '!text-[0.625rem] !px-1.5 !py-px !gap-0.5 sm:!text-[0.6875rem] sm:!px-2 sm:!gap-1',
        'md:!text-xs md:!px-2 md:!py-0.5 md:!gap-1 md:!rounded-lg',
        'lg:!text-xs lg:!px-2 lg:!py-0.5 lg:!gap-1'
      ].join(' '),
      content_stack: true,
      content_stack_class: 'gap-3 lg:gap-4 xl:gap-4',
      content_class: [
        'max-lg:!max-w-none max-lg:w-full max-lg:mx-auto max-lg:items-center max-lg:text-center',
        'lg:items-start lg:text-left lg:max-w-[26rem] xl:max-w-[30rem]'
      ].join(' '),
      title_class: [
        'text-center lg:text-left',
        'font-bold text-xl md:text-xl text-white drop-shadow-lg',
        'lg:font-extrabold lg:tracking-tight lg:leading-tight lg:text-3xl xl:text-[2rem]'
      ].join(' '),
      description_class: [
        'font-medium leading-snug tracking-tight text-white/90 drop-shadow-md',
        'text-sm lg:text-[0.9375rem] xl:text-base',
        'leading-snug xl:leading-snug'
      ].join(' '),
      button_variant: :primary,
      button_size: :md,
      button_class: [
        'group/btn transition-all duration-200 hover:!shadow-md',
        'lg:!px-4 lg:!py-2 lg:!text-sm',
        'xl:!px-4 xl:!py-2 xl:!text-sm'
      ].join(' '),
      button_arrow: true,
      button_arrow_class: 'lg:!h-3.5 lg:!w-3.5 xl:!h-3.5 xl:!w-3.5',
      button_stack_class: 'w-full lg:w-fit lg:self-start'
    }.freeze

    def fiction_genre_promo_card
      cta = user_signed_in? ? signed_in_promo_cta : guest_promo_cta
      FICTION_GENRE_PROMO_CARD.merge(cta)
    end

    private

    def guest_promo_cta
      { href: new_user_session_path, button_label: GUEST_PROMO_BUTTON_LABEL }
    end

    def signed_in_promo_cta
      { href: readings_path, button_label: SIGNED_IN_PROMO_BUTTON_LABEL }
    end
  end
end
