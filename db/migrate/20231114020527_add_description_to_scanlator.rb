class AddDescriptionToScanlator < ActiveRecord::Migration[7.0]
  def change
    remove_column :fictions, :translator, :string
    add_column :scanlators, :description, :string, after: :title
  end
end
