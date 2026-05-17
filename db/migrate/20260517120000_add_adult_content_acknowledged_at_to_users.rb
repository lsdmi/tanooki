# frozen_string_literal: true

class AddAdultContentAcknowledgedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :adult_content_acknowledged_at, :date, after: :latest_read_comment_id
  end
end
