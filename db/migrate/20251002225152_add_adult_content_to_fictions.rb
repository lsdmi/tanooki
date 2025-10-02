class AddAdultContentToFictions < ActiveRecord::Migration[8.0]
  def change
    add_column :fictions, :adult_content, :boolean, default: false, null: false, after: :origin
  end
end
