class AddStatusToReadingProgresses < ActiveRecord::Migration[7.2]
  def change
    add_column :reading_progresses, :status, :integer, default: 0, null: false, after: :chapter_id
    add_index :reading_progresses, :status
  end
end
