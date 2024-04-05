class ChangeChapterNumber < ActiveRecord::Migration[7.1]
  def change
    change_column :chapters, :number, :decimal, precision: 9, scale: 2
  end
end
