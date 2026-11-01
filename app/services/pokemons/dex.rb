# frozen_string_literal: true

module Pokemons
  # Species Pokédex for one trainer: unknown / seen / caught tiles, optional type filter, completion.
  # Raid-only legendaries (5.7) stay out via +DEX_EXCLUDED_IDS+; evolutions with +wild: false+ stay in.
  class Dex
    # National dex numbers that never count toward the Pokédex (weekly raid bosses). Empty until 5.7 seeds them.
    DEX_EXCLUDED_IDS = [].freeze

    Entry = Data.define(:pokemon, :state) do
      def unknown? = state == :unknown
      def seen? = state == :seen
      def caught? = state == :caught
    end

    TypeCompletion = Data.define(:type, :caught, :total)
    Completion = Data.define(:caught, :total)

    attr_reader :user, :type_key, :entries, :types, :type_completions, :caught_count, :total_count

    def initialize(user, type_key: nil)
      @user = user
      @type_key = type_key.presence
      @types = PokemonType.order(:key).to_a
      assign_catalog
    end

    # Caught species (owned stage + evolution ancestors) over the dex catalog — no sprite preload.
    def self.completion(user)
      caught = caught_species_ids_for(user)
      total = catalog_scope.count
      Completion.new(caught: catalog_scope.where(id: caught.to_a).count, total:)
    end

    def self.catalog_scope
      relation = Pokemon.all
      return relation if DEX_EXCLUDED_IDS.empty?

      relation.where.not(dex_id: DEX_EXCLUDED_IDS)
    end

    def self.caught_species_ids_for(user)
      owned_ids = UserPokemon.where(user_id: user.id).pluck(:pokemon_id)
      return Set.new if owned_ids.empty?

      with_evolution_ancestors(owned_ids)
    end

    def self.with_evolution_ancestors(owned_ids)
      parent_of = PokemonEvolution.pluck(:to_id, :from_id).to_h
      ids = Set.new(owned_ids)
      owned_ids.each do |species_id|
        current = species_id
        while (parent = parent_of[current])
          ids << parent
          current = parent
        end
      end
      ids
    end
    private_class_method :with_evolution_ancestors

    def filtered_type
      return if type_key.blank?

      types.find { |type| type.key == type_key }
    end

    private

    def assign_catalog
      species = load_species
      caught_ids = self.class.caught_species_ids_for(user)
      seen_ids = seen_species_ids | caught_ids
      @type_completions = type_completions_for(species, caught_ids)
      @entries = filtered_species(species).map { |pokemon| entry_for(pokemon, caught_ids, seen_ids) }
      @caught_count = @entries.count(&:caught?)
      @total_count = @entries.size
    end

    def load_species
      self.class.catalog_scope.includes(:pokemon_types, sprite_attachment: :blob).order(:dex_id).to_a
    end

    def filtered_species(species)
      return species if type_key.blank?

      species.select { |pokemon| pokemon.pokemon_types.any? { |t| t.key == type_key } }
    end

    def entry_for(pokemon, caught_ids, seen_ids)
      Entry.new(pokemon:, state: state_for(pokemon.id, caught_ids, seen_ids))
    end

    def state_for(pokemon_id, caught_ids, seen_ids)
      return :caught if caught_ids.include?(pokemon_id)
      return :seen if seen_ids.include?(pokemon_id)

      :unknown
    end

    def seen_species_ids
      Set.new(PokemonEncounter.where(user_id: user.id).distinct.pluck(:pokemon_id))
    end

    def type_completions_for(species, caught_ids)
      types.filter_map do |type|
        with_type = species.select { |pokemon| pokemon.pokemon_types.any? { |t| t.key == type.key } }
        next if with_type.empty?

        TypeCompletion.new(
          type:,
          caught: with_type.count { |pokemon| caught_ids.include?(pokemon.id) },
          total: with_type.size
        )
      end
    end
  end
end
