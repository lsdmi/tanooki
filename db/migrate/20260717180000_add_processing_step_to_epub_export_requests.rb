# frozen_string_literal: true

class AddProcessingStepToEpubExportRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :epub_export_requests, :processing_step, :string, after: :error_message
  end
end
