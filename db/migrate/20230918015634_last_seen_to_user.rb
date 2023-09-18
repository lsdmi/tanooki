class LastSeenToUser < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.datetime :pokemon_last_catch, default: Time.now, before: :created_at
    end
  end
end
