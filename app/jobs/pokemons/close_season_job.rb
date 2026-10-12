# frozen_string_literal: true

module Pokemons
  # Daily: close a Pokémon season whose last day has passed, soft-reset ratings, and open the next two-month block.
  class CloseSeasonJob < ApplicationJob
    queue_as :default

    def perform
      Seasons::Close.call
    end
  end
end
