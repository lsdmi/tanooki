class CreatePublications < ActiveRecord::Migration[7.0]
  def change
    create_table :publications do |t|
      t.string :slug, null: false
      t.string :type, null: false
      t.string :title, null: false
      t.boolean :highlight, default: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
      t.datetime :deleted_at
    end

    add_index :publications, :slug, unique: true
  end
end
