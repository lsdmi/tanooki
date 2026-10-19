# frozen_string_literal: true

module Pokemons
  # JSON script for +battle_replay_controller+: fighters (sprite, max HP) and the stored event list.
  class BattleReplayScript
    def initialize(battle, view:)
      @battle = battle
      @view = view
    end

    def as_json(*)
      {
        events: battle.events,
        fighters: fighters,
        hp: hp_bars?,
        labels: labels
      }
    end

    def hp_bars? = battle.engine_version.to_i >= 2

    private

    attr_reader :battle, :view

    def fighters
      rows = sides.flat_map { |side, team| team.map { |entry| fighter_entry(entry, side) } }
      rows.index_by { |row| row[:id].to_s }
    end

    def sides
      { attacker: battle.attacker_team, defender: battle.defender_team }
    end

    def fighter_entry(entry, side)
      combatant = combatant_from(entry)
      species = species_by_id[entry['pokemon_id']]
      {
        id: combatant.id,
        side: side.to_s,
        name: species&.name,
        sprite: sprite_url(species),
        maxHp: max_hp(combatant)
      }
    end

    def combatant_from(entry)
      Engine::Combatant.new(
        id: entry['id'], character: entry['character'], battle_experience: entry['battle_experience'].to_i,
        types: Array(entry['types']), power_level: entry['power_level'], base_hp: entry['base_hp'],
        base_attack: entry['base_attack']
      )
    end

    def max_hp(combatant)
      return unless hp_bars? && combatant.base_hp && combatant.base_attack

      Engine::HpBalance::V2.hp(combatant).round(4)
    end

    def sprite_url(species)
      return unless species&.sprite&.attached?

      view.url_for(species.sprite)
    end

    def species_by_id
      @species_by_id ||= begin
        ids = (battle.attacker_team + battle.defender_team).filter_map { |entry| entry['pokemon_id'] }.uniq
        Pokemon.where(id: ids).includes(sprite_attachment: :blob).index_by(&:id)
      end
    end

    def labels
      keys = %i[super weak crit dodged healed fainted play pause skip round striking]
      keys.index_with { |key| I18n.t(key, scope: 'pokemons.battle.replay') }
          .merge(traits: I18n.t('pokemons.characters'),
                 traitLines: I18n.t('pokemons.battle.replay.traits'))
    end
  end
end
