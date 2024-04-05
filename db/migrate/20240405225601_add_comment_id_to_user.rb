class AddCommentIdToUser < ActiveRecord::Migration[7.1]
  def change
    change_table :users do |t|
      t.references :latest_read_comment, foreign_key: { to_table: :comments }, after: :battle_win_rate
    end
  end
end
