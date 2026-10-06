# frozen_string_literal: true

# user_pokemons.character stores the trait key the engine already uses; the labels move to uk.yml
# (pokemons.characters). Rows the old code writes while this deploy rolls out are rewritten in a later deploy.
class KeyUserPokemonCharacters < ActiveRecord::Migration[8.1]
  LABELS = {
    'agile' => 'Меткий', 'ambitious' => 'Амбітний', 'brave' => 'Сміливий', 'confident' => 'Самовпевнений',
    'decisive' => 'Рішучий', 'friendly' => 'Дружелюбний', 'hardy' => 'Терплячий', 'independent' => 'Незалежний',
    'lucky' => 'Таланистий', 'patient' => 'Впертий', 'persistent' => 'Наполегливий', 'prideful' => 'Гордівливий'
  }.freeze

  def up
    rewrite(LABELS.invert)
    unknown = select_values('SELECT DISTINCT `character` FROM user_pokemons WHERE `character` NOT IN ' \
                            "(#{LABELS.keys.map { |key| quote(key) }.join(', ')})")
    raise "Unknown Pokémon characters: #{unknown.join(', ')}" if unknown.any?
  end

  def down
    rewrite(LABELS)
  end

  private

  def rewrite(mapping)
    mapping.each do |from, to|
      execute "UPDATE user_pokemons SET `character` = #{quote(to)} WHERE `character` = #{quote(from)}"
    end
  end
end
