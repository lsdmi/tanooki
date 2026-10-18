# frozen_string_literal: true

module Ui
  # Editorial badge for hero banners (18+, Новинка, Популярне, Оновлення).
  # Figma solid fill by default; :outline matches showcase genre-pill chrome (neutral veil tint).
  class EditorialTagComponent < ViewComponent::Base
    HERO_MAX = 2
    VARIANTS = %i[solid outline].freeze

    KINDS = {
      sixteen: { label: '16+', icon: :warning },
      adult: { label: '18+', icon: :warning },
      novelty: { label: 'Новинка', icon: :lightning },
      popular: { label: 'Популярне', icon: :star },
      update: { label: 'Оновлення', icon: :refresh }
    }.freeze

    SOLID_COLORS = {
      sixteen: 'bg-amber-600',
      adult: 'token-raw bg-rose-600',
      novelty: 'bg-violet-600',
      popular: 'bg-fuchsia-700',
      update: 'bg-teal-600'
    }.freeze

    # Neutral veil chip shared by showcase editorial tags.
    # Light: soft gray + secondary ink; dark: white wash on the banner.
    OUTLINE_CHROME = 'bg-fg/3 text-fg ring-fg/70 hover:bg-fg/6 ' \
                     'dark:bg-white/10 dark:text-white dark:ring-white/70 ' \
                     'dark:hover:bg-white/15 dark:hover:text-white'

    def initialize(kind:, label: nil, variant: :solid)
      super()
      @kind = kind.to_sym
      @variant = variant.to_sym
      raise ArgumentError, "unknown kind: #{@kind}" unless KINDS.key?(@kind)
      raise ArgumentError, "unknown variant: #{@variant}" unless VARIANTS.include?(@variant)

      @label = label.presence || KINDS.fetch(@kind)[:label]
    end

    private

    attr_reader :kind, :label, :variant

    def icon
      KINDS.fetch(kind)[:icon]
    end

    def outline?
      variant == :outline
    end

    def kind_classes
      outline? ? OUTLINE_CHROME : SOLID_COLORS.fetch(kind)
    end

    def base_classes
      if outline?
        'inline-flex items-center gap-1 rounded-md px-2.5 py-1 text-sm/4 font-medium ' \
          'ring-1 ring-inset transition-colors'
      else
        'inline-flex items-center gap-1 rounded-lg px-2.5 py-0.5 text-sm font-normal text-white ' \
          'md:gap-1.5 md:rounded-xl md:px-3 md:py-1 md:text-lg'
      end
    end

    def icon_classes
      outline? ? 'h-3.5 w-3.5 shrink-0' : 'h-4 w-4 shrink-0 md:h-5 md:w-5'
    end
  end
end
