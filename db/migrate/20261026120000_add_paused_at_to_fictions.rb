# frozen_string_literal: true

# Team-declared hiatus of the source work. The badge is derived from this timestamp later.
class AddPausedAtToFictions < ActiveRecord::Migration[8.1]
  def change
    change_table :fictions, bulk: true do |t|
      t.datetime :paused_at, after: :completed_at
      t.index :paused_at
    end
  end
end
