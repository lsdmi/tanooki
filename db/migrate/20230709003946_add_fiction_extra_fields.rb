class AddFictionExtraFields < ActiveRecord::Migration[7.0]
  def change
    add_column :chapters, :volume_number, :decimal, precision: 9, scale: 1, after: :number

    reversible do |dir|
      dir.up do
        change_column :chapters, :number, :decimal, precision: 9, scale: 1
      end

      dir.down do
        change_column :chapters, :number, :integer
      end
    end
  end
end
