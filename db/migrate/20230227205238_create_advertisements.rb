class CreateAdvertisements < ActiveRecord::Migration[7.0]
  def change
    create_table :advertisements do |t|
      t.string :slug, null: false
      t.string :caption, null: false
      t.string :resource, null: false
      t.boolean :enabled, default: false

      t.timestamps
    end

    add_index :advertisements, :enabled
    add_index :advertisements, :slug, unique: true
  end
end
