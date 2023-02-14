class CreateBlogs < ActiveRecord::Migration[7.0]
  def change
    create_table :blogs do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.boolean :hidden, default: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :blogs, :slug, unique: true
  end
end
