class CreateReadingProgresses < ActiveRecord::Migration[7.0]
  def change
    create_table :reading_progresses do |t|
      t.references :fiction, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :chapter, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
