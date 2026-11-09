# frozen_string_literal: true

# Contests no longer gate on word volume; chapter stats keep excerpt/body_bytes only.
class DropChapterAndContestWordVolume < ActiveRecord::Migration[8.1]
  def change
    remove_column :chapters, :word_count, :integer, default: 0, null: false
    remove_column :contests, :min_words, :integer
    remove_column :contests, :max_words, :integer
    remove_column :contests, :judged_word_cap, :integer
  end
end
