# frozen_string_literal: true

# Server-side matchmaking: the battle endpoint fights the pinned opponent instead of a defender id from the form.
# No foreign key or index: nothing queries by these columns, and Matchmaker drops a pin whose user is gone.
class AddPinnedOpponentToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.bigint :pinned_opponent_id, after: :battle_win_rate
      t.datetime :pinned_until, after: :pinned_opponent_id
      t.datetime :opponent_rerolled_at, after: :pinned_until
    end
  end
end
