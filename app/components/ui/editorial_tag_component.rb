# frozen_string_literal: true

module Ui
  # Editorial badge for hero banners (18+, Новинка, Популярне, Оновлення).
  # Figma: flat solid fill rounded rect — see docs/TAG_SYSTEM_REFERENCE.md.
  class EditorialTagComponent < ViewComponent::Base
    HERO_MAX = 2

    KINDS = {
      adult: { label: '18+', icon: :warning },
      novelty: { label: 'Новинка', icon: :lightning },
      popular: { label: 'Популярне', icon: :star },
      update: { label: 'Оновлення', icon: :refresh }
    }.freeze

    KIND_COLORS = {
      adult: 'bg-rose-600',
      novelty: 'bg-violet-600',
      popular: 'bg-fuchsia-700',
      update: 'bg-teal-600'
    }.freeze

    def initialize(kind:, label: nil)
      super()
      @kind = kind.to_sym
      raise ArgumentError, "unknown kind: #{@kind}" unless KINDS.key?(@kind)

      @label = label.presence || KINDS.fetch(@kind)[:label]
    end

    private

    attr_reader :kind, :label

    def icon
      KINDS.fetch(kind)[:icon]
    end

    def kind_classes
      KIND_COLORS.fetch(kind)
    end

    def base_classes
      'inline-flex items-center gap-1 rounded-lg px-2.5 py-0.5 text-sm font-normal text-white ' \
        'md:gap-1.5 md:rounded-xl md:px-3 md:py-1 md:text-lg'
    end

    def icon_classes
      'h-4 w-4 shrink-0 md:h-5 md:w-5'
    end
  end
end
