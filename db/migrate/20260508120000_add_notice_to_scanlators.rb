# frozen_string_literal: true

class AddNoticeToScanlators < ActiveRecord::Migration[8.0]
  def change
    add_column :scanlators, :notice, :string, after: :description
  end
end
