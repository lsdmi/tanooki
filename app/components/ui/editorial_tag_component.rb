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
      adult: 'bg-red-600',
      novelty: 'bg-blue-600',
      popular: 'bg-amber-500',
      update: 'bg-orange-600'
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
      'inline-flex items-center gap-1.5 rounded-xl px-3 py-1 text-lg font-normal text-white'
    end

    def icon_classes
      'h-5 w-5 shrink-0'
    end
  end
end
