class CreateAvatars < ActiveRecord::Migration[7.0]
  def change
    create_table :avatars do |t|
      t.timestamps
    end

    add_reference :users, :avatar, foreign_key: true, after: :admin
  end
end
