class AddAlternativeNamesToFiction < ActiveRecord::Migration[7.0]
  def change
    add_column :fictions, :alternative_title, :string, after: :title
    add_column :fictions, :english_title, :string, after: :alternative_title
  end
end
