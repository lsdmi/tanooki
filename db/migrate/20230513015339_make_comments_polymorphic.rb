class MakeCommentsPolymorphic < ActiveRecord::Migration[7.0]
  def change
    remove_column :comments, :publication_id, :integer
    add_reference :comments, :commentable, polymorphic: true, null: false, after: :parent_id
  end
end
