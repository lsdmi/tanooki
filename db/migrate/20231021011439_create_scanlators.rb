class CreateScanlators < ActiveRecord::Migration[7.0]
  def change
    create_table :scanlators do |t|
      t.string :slug, null: false
      t.string :telegram_id
      t.string :title, null: false

      t.timestamps
    end

    create_table :chapter_scanlators do |t|
      t.references :chapter, foreign_key: true, null: false
      t.references :scanlator, foreign_key: true, null: false

      t.timestamps
    end

    create_table :fiction_scanlators do |t|
      t.references :fiction, foreign_key: true, null: false
      t.references :scanlator, foreign_key: true, null: false

      t.timestamps
    end

    create_table :scanlator_users do |t|
      t.references :scanlator, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
  end
end
