# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :parent, foreign_key: { to_table: :comments, on_delete: :cascade }
      t.references :publication, null: false, foreign_key: { on_delete: :cascade }
      t.text :content

      t.timestamps
    end
  end
end
