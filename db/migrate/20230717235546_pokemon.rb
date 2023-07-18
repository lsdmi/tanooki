class Pokemon < ActiveRecord::Migration[7.0]
  def change
    create_table :pokemons do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.integer :power_level, null: false
      t.integer :rarity, null: false
      t.timestamps
    end

    create_table :user_pokemons do |t|
      t.references :pokemon, foreign_key: true
      t.references :user, foreign_key: true
      t.timestamps
    end

    add_index :pokemons, :name
  end
end
