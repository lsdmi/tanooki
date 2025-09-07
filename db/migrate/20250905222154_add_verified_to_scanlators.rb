class AddVerifiedToScanlators < ActiveRecord::Migration[8.0]
  def change
    add_column :scanlators, :verified, :boolean, default: false, after: :convertable
  end
end
