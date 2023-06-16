class AddCommentsCountToModels < ActiveRecord::Migration[7.0]
  def change
    add_column :chapters, :comments_count, :integer, default: 0, after: :number
    add_column :fictions, :comments_count, :integer, default: 0, after: :description
    add_column :publications, :comments_count, :integer, default: 0, after: :user_id
  end
end
