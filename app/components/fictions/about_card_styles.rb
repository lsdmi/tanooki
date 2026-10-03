# frozen_string_literal: true

module Fictions
  # Card shell shared by the About tab sidebar blocks (Figma «About Tab» 10185:16863: 20 px padding, 18 px titles).
  # On mobile (spacing spec 10221:2168) shelves and rating are tighter, with 16 px titles; honors stay as on desktop.
  # Figma strokes sit inside the frame, so cards outline with an inset ring: a border would add 2 px of height.
  module AboutCardStyles
    OUTLINE = 'ring-1 ring-inset ring-line'
    SHELL = "relative flex flex-col overflow-visible rounded-xl bg-main #{OUTLINE}".freeze
    HONORS_CARD = "#{SHELL} gap-4 p-5".freeze
    SHELVES_CARD = "#{SHELL} gap-3 p-4 md:gap-4 md:p-5".freeze
    RATING_CARD = "#{SHELL} gap-3 p-5 md:gap-4".freeze
    TITLE = 'text-lg/7 font-semibold text-fg'
    SMALL_TITLE = 'text-base/6 font-semibold text-fg md:text-lg/7'
  end
end
