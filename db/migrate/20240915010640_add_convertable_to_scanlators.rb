class AddConvertableToScanlators < ActiveRecord::Migration[7.2]
  def change
    add_column :scanlators, :convertable, :boolean, default: true, after: :description
  end
end
