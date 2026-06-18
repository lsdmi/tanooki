# frozen_string_literal: true

module Ui
  # Shared SVG and Tailwind classes for Ui::StarRatingComponent.
  module StarRatingComponentStyles
    STAR_PATH = [
      'M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81',
      'l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0',
      'l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72',
      'c-.783-.57-.38-1.81.588-1.81',
      'h3.461a1 1 0 00.951-.69l1.07-3.292z'
    ].join.freeze

    STAR_SIZE_CLASSES = 'w-3 h-3 sm:w-4 sm:h-4'
    FULL_STAR_CLASSES = "#{STAR_SIZE_CLASSES} text-yellow-400 fill-current".freeze
    EMPTY_STAR_CLASSES = "#{STAR_SIZE_CLASSES} text-stone-400 fill-current".freeze
    HALF_STAR_OVERLAY_CLASSES = [
      STAR_SIZE_CLASSES,
      'text-yellow-400 fill-current absolute top-0 left-0 overflow-hidden'
    ].join(' ').freeze
    HALF_STAR_CLIP_STYLE = 'clip-path: inset(0 50% 0 0);'

    VALUE_CLASSES = 'text-base sm:text-xl md:text-2xl font-bold anime-text text-stone-100'
    EMPTY_VALUE_CLASSES = 'text-base sm:text-xl md:text-2xl font-bold anime-text text-stone-400'
    LABEL_CLASSES = 'text-xs sm:text-sm md:text-base text-stone-300'
  end
end
