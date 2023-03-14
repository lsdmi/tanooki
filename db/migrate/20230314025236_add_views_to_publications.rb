class AddViewsToPublications < ActiveRecord::Migration[7.0]
  def change
    add_column :publications, :views, :integer, default: 0, after: :user_id
  end
end
