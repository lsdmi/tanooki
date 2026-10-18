# frozen_string_literal: true

module Pokemons
  # Resolves a trainer's ordered attack or defense team. Configured ids on +TrainerProfile+ win when every id is
  # still in the party; otherwise auto-fills up to +Balance::TEAM_SIZE+ by engine power (then id).
  class TeamRoster
    ROLES = {
      attack: :attack_team_ids,
      defense: :defense_team_ids
    }.freeze

    def initialize(user, role, party: nil)
      @user = user
      @role = role.to_sym
      @party = party
      raise ArgumentError, "unknown role: #{role}" unless ROLES.key?(@role)
    end

    def records
      ids = configured_ids
      return auto_fill if ids.nil?

      by_id = party.index_by(&:id)
      ordered = ids.filter_map { |id| by_id[id] }
      return auto_fill if ordered.empty? || ordered.size != ids.size

      ordered
    end

    def ids
      records.map(&:id)
    end

    # Persists an ordered list of +user_pokemon+ ids for +role+. Blank clears the column (auto-fill next fight).
    def self.update!(user, role:, user_pokemon_ids:)
      column = ROLES.fetch(role.to_sym)
      ids = Array(user_pokemon_ids).map(&:to_i).uniq
      raise ArgumentError, 'too many' if ids.size > Balance::TEAM_SIZE
      raise ArgumentError, 'foreign' unless owned_ids?(user, ids)

      user.trainer_profile.update!(column => ids.presence)
    end

    def self.owned_ids?(user, ids)
      UserPokemon.where(user_id: user.id, id: ids).count == ids.size
    end
    private_class_method :owned_ids?

    private

    attr_reader :user, :role

    def profile
      user.trainer_profile
    end

    def party
      @party ||= UserPokemon.where(user_id: user.id).includes(pokemon: :pokemon_types).to_a
    end

    def configured_ids
      raw = profile.public_send(ROLES.fetch(role))
      return if raw.blank?

      Array(raw).map(&:to_i)
    end

    def auto_fill
      balance = Engine::HpBalance::V2
      party.sort_by { |record| [-power(record, balance), record.id] }.first(Balance::TEAM_SIZE)
    end

    def power(record, balance)
      combatant = Engine::Combatant.new(
        id: record.id, character: record.character, battle_experience: record.battle_experience,
        types: record.pokemon.types.map(&:key), base_hp: record.pokemon.base_hp,
        base_attack: record.pokemon.base_attack
      )
      balance.hp(combatant) * balance.attack(combatant)
    end
  end
end
