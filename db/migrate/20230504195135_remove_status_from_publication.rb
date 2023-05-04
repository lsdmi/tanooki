class RemoveStatusFromPublication < ActiveRecord::Migration[7.0]
  def change
    remove_column :publications, :status, :string, null: false, after: :title, if_exists: true
    remove_column :publications, :status_message, :string, null: false, after: :status, if_exists: true
  end
end
