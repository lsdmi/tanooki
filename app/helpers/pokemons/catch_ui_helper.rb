# frozen_string_literal: true

module Pokemons
  # Tailwind class bundles for wild-catch sprite motion (states via +data-catch+ on the group).
  module CatchUiHelper
    SHELL = [
      'group relative pokemon-catch inline-flex items-center justify-center',
      'data-[catch]:[&_button]:pointer-events-none'
    ].join(' ').freeze

    SPRITE = [
      'cursor-pointer max-h-24 max-w-24 object-contain motion-reduce:animate-none',
      'group-data-[catch=busy]:animate-pokemon-catch-pulse',
      'group-data-[catch=success]:animate-pokemon-catch-sprite-in',
      'group-data-[catch=failure]:animate-pokemon-catch-sprite-out'
    ].join(' ').freeze
  end
end
