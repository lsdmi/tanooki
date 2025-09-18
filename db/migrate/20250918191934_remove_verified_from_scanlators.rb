class RemoveVerifiedFromScanlators < ActiveRecord::Migration[8.0]
  def change
    remove_column :scanlators, :verified, :boolean, default: false
  end
end
