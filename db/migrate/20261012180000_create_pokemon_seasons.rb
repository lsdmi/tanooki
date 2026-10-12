# frozen_string_literal: true

# Seasons (two calendar months) for the Pokémon ladder: final standings in season_results, soft reset toward 1500
# when a season closes, and titles / the top counted among trainers who fought in the open season. Battles carry the
# season they were fought in; older rows stay null. The first open season starts today and ends with the current
# two-month block (Jan–Feb, Mar–Apr, …).
class CreatePokemonSeasons < ActiveRecord::Migration[8.1]
  # Local model so the migration can seed season 1 without loading app/models.
  class Season < ApplicationRecord
    self.table_name = 'pokemon_seasons'
  end

  def up
    create_seasons
    create_results
    add_reference :pokemon_battles, :pokemon_season, foreign_key: true, after: :ranked
    open_first_season
  end

  def down
    remove_reference :pokemon_battles, :pokemon_season, foreign_key: true
    drop_table :season_results
    drop_table :pokemon_seasons
  end

  private

  def create_seasons
    create_table :pokemon_seasons, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.integer :number, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.datetime :closed_at
      t.timestamps
      t.index :number, unique: true
      t.index :starts_on
    end
  end

  def create_results
    create_table :season_results, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :pokemon_season, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      result_stats(t)
      t.timestamps
    end
    add_index :season_results, %i[pokemon_season_id user_id], unique: true
    add_index :season_results, %i[pokemon_season_id place]
  end

  def result_stats(table)
    table.integer :place, null: false
    table.float :percentile, limit: 53, null: false
    table.float :glicko_rating, limit: 53, null: false
    table.float :glicko_deviation, limit: 53, null: false
    table.float :glicko_floor, limit: 53, null: false
    table.integer :battles, null: false, default: 0
    table.integer :wins, null: false, default: 0
  end

  def open_first_season
    today = Time.zone.today
    start_month = (((today.month - 1) / 2) * 2) + 1
    ends_on = (Date.new(today.year, start_month, 1) >> 2) - 1
    Season.create!(number: 1, starts_on: today, ends_on:)
  end
end
