# frozen_string_literal: true

# Finishes the move to evolution lines once no running code reads the old columns. Characters the previous release
# could still write as Ukrainian labels become keys; every user_pokemons row gets its line; an evolved form takes its
# line root's rarity (only first forms are wild, so rarity 5 is free for species that never are); and the
# ancestor/descendant columns go, with line_root_id taking over their foreign keys.
class FinishPokemonLines < ActiveRecord::Migration[8.1]
  KEYS = {
    'Меткий' => 'agile', 'Амбітний' => 'ambitious', 'Сміливий' => 'brave', 'Самовпевнений' => 'confident',
    'Рішучий' => 'decisive', 'Дружелюбний' => 'friendly', 'Терплячий' => 'hardy', 'Незалежний' => 'independent',
    'Таланистий' => 'lucky', 'Впертий' => 'patient', 'Наполегливий' => 'persistent', 'Гордівливий' => 'prideful'
  }.freeze

  # Rarity and updated_at together: the wild pool cache is keyed by the newest updated_at.
  ROOT_RARITY = <<~SQL.squish
    UPDATE pokemons JOIN pokemons AS roots ON roots.id = pokemons.line_root_id
    SET pokemons.rarity = roots.rarity, pokemons.updated_at = UTC_TIMESTAMP(6)
    WHERE pokemons.id <> pokemons.line_root_id AND pokemons.rarity <> roots.rarity
  SQL

  # The old columns as the previous code expects them: the line root as ancestor, the only evolution as descendant
  # (a species with branches or none is its own final form) and rarity 5 for every evolved form.
  RESTORE = <<~SQL.squish
    UPDATE pokemons
    LEFT JOIN (SELECT from_id, MIN(to_id) AS to_id, MIN(min_level) AS min_level FROM pokemon_evolutions
               GROUP BY from_id HAVING COUNT(*) = 1) AS evolutions ON evolutions.from_id = pokemons.id
    SET pokemons.ancestor_id = pokemons.line_root_id,
        pokemons.descendant_id = COALESCE(evolutions.to_id, pokemons.id),
        pokemons.descendant_level = COALESCE(evolutions.min_level, 0),
        pokemons.rarity = IF(pokemons.id = pokemons.line_root_id, pokemons.rarity, 5),
        pokemons.updated_at = UTC_TIMESTAMP(6)
  SQL

  def up
    key_characters
    execute <<~SQL.squish
      UPDATE user_pokemons JOIN pokemons ON pokemons.id = user_pokemons.pokemon_id
      SET user_pokemons.line_root_id = pokemons.line_root_id
      WHERE user_pokemons.line_root_id IS NULL
    SQL
    change_column_null :user_pokemons, :line_root_id, false
    execute ROOT_RARITY

    remove_foreign_key :pokemons, column: :ancestor_id
    remove_foreign_key :pokemons, column: :descendant_id
    change_table :pokemons, bulk: true do |t|
      t.remove_index :ancestor_id
      t.remove_index :descendant_id
      t.remove :ancestor_id, :descendant_id, :descendant_level
    end
    add_foreign_key :pokemons, :pokemons, column: :line_root_id
    add_index :user_pokemons, :line_root_id
    add_foreign_key :user_pokemons, :pokemons, column: :line_root_id
  end

  def down
    remove_foreign_key :user_pokemons, column: :line_root_id
    remove_index :user_pokemons, :line_root_id
    remove_foreign_key :pokemons, column: :line_root_id
    change_table :pokemons, bulk: true do |t|
      t.bigint :ancestor_id, after: :id
      t.bigint :descendant_id, after: :created_at
      t.integer :descendant_level, after: :descendant_id
      t.index :ancestor_id
      t.index :descendant_id
    end
    execute RESTORE
    add_foreign_key :pokemons, :pokemons, column: :ancestor_id
    add_foreign_key :pokemons, :pokemons, column: :descendant_id
    change_column_null :user_pokemons, :line_root_id, true
  end

  private

  def key_characters
    KEYS.each do |label, key|
      execute "UPDATE user_pokemons SET `character` = #{quote(key)} WHERE `character` = #{quote(label)}"
    end
    unknown = select_values('SELECT DISTINCT `character` FROM user_pokemons WHERE `character` NOT IN ' \
                            "(#{KEYS.values.map { |key| quote(key) }.join(', ')})")
    raise "Unknown Pokémon characters: #{unknown.join(', ')}" if unknown.any?
  end
end
