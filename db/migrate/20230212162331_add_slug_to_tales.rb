# frozen_string_literal: true

class AddSlugToTales < ActiveRecord::Migration[7.0]
  def change
    add_column :tales, :slug, :string, after: :id
    add_index :tales, :slug, unique: true
  end
end
