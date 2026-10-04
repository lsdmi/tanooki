# frozen_string_literal: true

# Species HP and attack for engine version 2, seeded from the official stats by dex number. Version 1 keeps reading
# power_level until new battles switch.
class AddBaseStatsToPokemons < ActiveRecord::Migration[8.1]
  class MissingStats < StandardError; end

  def up
    change_table :pokemons, bulk: true do |t|
      t.integer :base_hp, limit: 2, after: :power_level
      t.integer :base_attack, limit: 2, after: :base_hp
    end
    backfill
    change_table :pokemons, bulk: true do |t|
      t.change_null :base_hp, false
      t.change_null :base_attack, false
    end
  end

  def down
    remove_columns :pokemons, :base_hp, :base_attack
  end

  private

  def backfill
    stats = select_values('SELECT DISTINCT dex_id FROM pokemons').index_with { |dex_id| Pokemons::BaseStats.for(dex_id) }
    missing = stats.filter_map { |dex_id, species| dex_id.inspect if species.nil? }
    raise MissingStats, "No base stats for dex_id #{missing.join(', ')}" if missing.any?
    return if stats.empty?

    execute <<~SQL.squish
      UPDATE pokemons
      SET base_hp = CASE dex_id #{when_clauses(stats, :hp)} END,
          base_attack = CASE dex_id #{when_clauses(stats, :attack)} END
    SQL
  end

  def when_clauses(stats, stat)
    stats.map { |dex_id, species| "WHEN #{Integer(dex_id)} THEN #{Integer(species.fetch(stat))}" }.join(' ')
  end
end
