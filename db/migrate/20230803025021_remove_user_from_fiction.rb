class RemoveUserFromFiction < ActiveRecord::Migration[7.0]
  def change
    remove_column :fictions, :user_id
  end
end
