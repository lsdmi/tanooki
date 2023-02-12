# frozen_string_literal: true

class CreateTales < ActiveRecord::Migration[7.0]
  def change
    create_table :tales do |t|
      t.string :title, null: false
      t.boolean :highlight, default: false

      t.timestamps
    end
  end
end
