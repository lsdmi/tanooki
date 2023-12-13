class DropUserFictions < ActiveRecord::Migration[7.0]
  def change
    drop_table :user_fictions
  end
end
