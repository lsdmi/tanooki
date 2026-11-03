# frozen_string_literal: true

class AddUniqueIndexToContestAwardsOnEntryAndPrize < ActiveRecord::Migration[8.1]
  def change
    add_index :contest_awards, %i[contest_entry_id contest_prize_id],
              unique: true,
              name: 'index_contest_awards_on_entry_and_prize'
  end
end
