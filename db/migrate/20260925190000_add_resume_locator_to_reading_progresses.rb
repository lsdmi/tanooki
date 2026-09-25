# frozen_string_literal: true

# Where inside the resume chapter the reader stopped (see Reading::ResumeLocator). Null until the reader reports
# a position, and cleared whenever the resume cursor moves to another chapter.
class AddResumeLocatorToReadingProgresses < ActiveRecord::Migration[8.1]
  def change
    change_table :reading_progresses, bulk: true do |t|
      t.string :resume_quote, limit: 120, null: true, after: :resume_at
      t.integer :resume_block_index, null: true, after: :resume_quote
      t.decimal :resume_percent, precision: 5, scale: 2, null: true, after: :resume_block_index
      t.string :resume_digest, limit: 64, null: true, after: :resume_percent
    end
  end
end
