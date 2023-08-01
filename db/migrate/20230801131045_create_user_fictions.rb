class CreateUserFictions < ActiveRecord::Migration[7.0]
  def change
    create_table :user_fictions do |t|
      t.references :fiction, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
  end
end
