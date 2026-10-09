# frozen_string_literal: true

# One trainer-vs-trainer battle, stored as data: the teams as they entered (with each Pokémon's species), the seed and
# engine version that replay it, the engine's events, and the rating change for each side.
class PokemonBattle < ApplicationRecord
  belongs_to :attacker, class_name: 'User'
  belongs_to :defender, class_name: 'User'
  belongs_to :winner, class_name: 'User'

  FLOAT_DIGITS = 4
  # Converted from pokemon_battle_logs: who fought, who won and when, nothing to replay.
  LEGACY_VERSION = 0

  after_create_commit -> { Pokemons::DexLeaderboard.expire_top }, if: :ranked?

  scope :involving, ->(user) { where(attacker_id: user.id).or(where(defender_id: user.id)) }
  scope :between, lambda { |one, other|
    where(attacker_id: one.id, defender_id: other.id).or(where(attacker_id: other.id, defender_id: one.id))
  }
  scope :legacy, -> { where(engine_version: LEGACY_VERSION) }

  # Fits the signed BIGINT column.
  def self.new_seed
    SecureRandom.random_number(1 << 63)
  end

  # +rating_deltas+ by user id, or nil for an unranked battle.
  def self.record!(teams:, seed:, result:, rating_deltas:)
    attacker, defender = teams.trainers
    create!(attacker:, defender:, winner: result.attacker_won? ? attacker : defender, seed:,
            engine_version: result.engine_version, events: serialize(result.events),
            attacker_team: teams.stored(:attacker), defender_team: teams.stored(:defender), ranked: !rating_deltas.nil?,
            rating_delta_attacker: rating_deltas&.fetch(attacker.id) || 0,
            rating_delta_defender: rating_deltas&.fetch(defender.id) || 0)
  end

  # True when the pair already fought within Balance::RANKED_REMATCH_GAP, either side attacking.
  def self.rematch?(attacker, defender, at: Time.current)
    between(attacker, defender).exists?(created_at: (at - Pokemons::Balance::RANKED_REMATCH_GAP)..)
  end

  # The JSON column's form: string keys and values. MySQL's JSON type prints doubles with 16 significant digits, so
  # full floats would not come back unchanged; scores and tiredness are stored to FLOAT_DIGITS decimals. Replay from
  # the seed for exact values.
  def self.serialize(events)
    rows = events.map { |event| event.to_h.merge(data: event.data.transform_values { |value| stored_value(value) }) }
    JSON.parse(rows.to_json)
  end

  def self.stored_value(value)
    value.is_a?(Float) ? value.round(FLOAT_DIGITS) : value
  end

  def team(side)
    public_send(:"#{side}_team")
  end

  def snapshot(side)
    combatants = team(side).map do |entry|
      Pokemons::Engine::Combatant.new(**entry.symbolize_keys.slice(*Pokemons::Engine::Combatant.members))
    end
    Pokemons::Engine::TeamSnapshot.new(trainer_id: public_send(:"#{side}_id"), combatants:)
  end

  def replay
    Pokemons::Engine.simulate(attacker: snapshot(:attacker), defender: snapshot(:defender), seed:,
                              version: engine_version)
  end

  def events_of(type)
    events.select { |event| event['type'] == type.to_s }
  end

  def attacker_won?
    winner_id == attacker_id
  end

  def legacy?
    engine_version == LEGACY_VERSION
  end
end
