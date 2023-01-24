class CreateTales < ActiveRecord::Migration[7.0]
  def change
    create_table :tales do |t|
      t.string :title, null: false
      t.text :description, null: false

      t.timestamps
    end
  end
end
