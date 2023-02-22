class AddStatusToPublication < ActiveRecord::Migration[7.0]
  def change
    add_column :publications, :status, :string, null: false, after: :title
    add_column :publications, :status_message, :string, null: false, after: :status

    add_index :publications, :status
  end
end
