class PokemonLastTrainingToUser < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.datetime :pokemon_last_training, default: Time.now, after: :pokemon_last_catch
    end
  end
end
