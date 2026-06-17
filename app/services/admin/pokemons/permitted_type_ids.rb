# frozen_string_literal: true

module Admin
  module Pokemons
    # Filters submitted Pokemon type IDs to rows that exist in the catalog.
    class PermittedTypeIds
      def self.filter(ids)
        submitted = Array(ids).compact_blank.map(&:to_i).uniq
        return [] if submitted.empty?

        PokemonType.where(id: submitted).ids
      end
    end
  end
end
