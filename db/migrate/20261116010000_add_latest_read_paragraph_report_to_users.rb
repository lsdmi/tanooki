# frozen_string_literal: true

class AddLatestReadParagraphReportToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :latest_read_paragraph_report,
                  foreign_key: { to_table: :paragraph_reports },
                  null: true,
                  after: :latest_read_comment_id
  end
end
