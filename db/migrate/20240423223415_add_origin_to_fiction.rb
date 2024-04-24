class AddOriginToFiction < ActiveRecord::Migration[7.1]
  def change
    add_column :fictions, :origin, :string, after: :author
  end
end
