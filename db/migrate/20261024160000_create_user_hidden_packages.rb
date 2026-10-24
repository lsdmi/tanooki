# frozen_string_literal: true

# Packages replace the free genre blocklist. Old per-genre rows no longer apply.
class CreateUserHiddenPackages < ActiveRecord::Migration[8.1]
  def up
    create_table :user_hidden_packages do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :package_key, null: false
      t.timestamps
    end
    add_index :user_hidden_packages, %i[user_id package_key], unique: true

    execute 'DELETE FROM user_hidden_genres'
  end

  def down
    drop_table :user_hidden_packages
  end
end
