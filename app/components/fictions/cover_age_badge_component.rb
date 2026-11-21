# frozen_string_literal: true

module Fictions
  # 16+ / 18+ mark drawn as the bare age icon (svgrepo age-16 / age-18), no text chip.
  #
  # - `placement: :corner_right` (default) / `:corner_left` pin it to a corner of a `relative` wrapper. Icons sit on a
  #   faint dark disc so they read on any cover: red for 18+, orange for 16+.
  # - `placement: :inline` is for rows on the page background (bookshelves hub): same hues, darker in light mode.
  #
  # Pass a `fiction` (its own rating) or a `rating` key ('sixteen' / 'eighteen', e.g. a shelf's max rating).
  # Editorial hero chips (Fictions::ShowcaseSlideOverlayComponent) keep their own tag row.
  class CoverAgeBadgeComponent < ViewComponent::Base
    CORNER_CLASS = 'pointer-events-none absolute z-10 flex items-center justify-center rounded-full bg-black/20 ' \
                   'drop-shadow-[0_1px_2px_rgb(0_0_0/0.6)]'
    INLINE_CLASS = 'inline-flex shrink-0 items-center justify-center'
    SIZES = {
      sm: { corner: 'top-1 right-1 p-0.5', icon: 'size-4' },
      md: { corner: 'top-1 right-1 p-0.5', icon: 'size-5' },
      lg: { corner: 'top-1.5 right-1.5 p-1 md:top-3 md:right-3', icon: 'size-8 md:size-9' }
    }.freeze
    CORNER_COLOURS = {
      'eighteen' => 'text-red-500',
      'sixteen' => 'text-orange-400'
    }.freeze
    INLINE_COLOURS = {
      'eighteen' => 'text-red-600 dark:text-red-400',
      'sixteen' => 'text-orange-600 dark:text-orange-400'
    }.freeze
    ICONS = {
      'eighteen' => Rails.root.join('app/assets/images/age/age-18.svg').read.freeze,
      'sixteen' => Rails.root.join('app/assets/images/age/age-16.svg').read.freeze
    }.freeze
    LABELS = {
      'eighteen' => FictionContentRating::EIGHTEEN_LABEL,
      'sixteen' => FictionContentRating::SIXTEEN_LABEL
    }.freeze

    # decorative: for covers that are themselves hidden from assistive tech (stacks), so the mark is not announced.
    def initialize(fiction: nil, rating: nil, size: :md, placement: :corner_right, decorative: false)
      super()
      @rating = (rating || fiction&.content_rating)&.to_s
      @size = size
      @placement = placement
      @decorative = decorative
    end

    def render?
      ICONS.key?(rating)
    end

    private

    attr_reader :rating, :size, :placement, :decorative

    def box_class
      return [INLINE_CLASS, INLINE_COLOURS.fetch(rating)].join(' ') if placement == :inline

      corner = SIZES.fetch(size)[:corner]
      corner = corner.gsub('right', 'left') if placement == :corner_left
      [CORNER_CLASS, CORNER_COLOURS.fetch(rating), corner].join(' ')
    end

    def a11y
      decorative ? { aria: { hidden: true } } : { role: 'img', aria: { label: LABELS.fetch(rating) } }
    end

    # The icon takes its colour from the text colour (`currentColor`).
    def icon_markup
      svg = ICONS.fetch(rating)
                 .sub('<svg ', %(<svg class="#{SIZES.fetch(size)[:icon]}" aria-hidden="true" focusable="false" ))
      # Trusted: a bundled SVG constant read at boot, never user input.
      ActiveSupport::SafeBuffer.new(svg)
    end
  end
end
