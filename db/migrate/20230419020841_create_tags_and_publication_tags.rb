class CreateTagsAndPublicationTags < ActiveRecord::Migration[7.0]
  def change
    create_table :tags do |t|
      t.string :name
      t.timestamps
    end

    create_table :publication_tags do |t|
      t.references :publication, foreign_key: true
      t.references :tag, foreign_key: true
      t.timestamps
    end

    add_index :tags, :name
  end
end
