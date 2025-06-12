class AddShortDescriptionToFictions < ActiveRecord::Migration[7.2]
  def change
    add_column :fictions, :short_description, :text, after: :description
  end
end
