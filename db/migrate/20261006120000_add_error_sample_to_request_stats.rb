# frozen_string_literal: true

# The first server error of the hour for each action: exception, app line and request path.
class AddErrorSampleToRequestStats < ActiveRecord::Migration[8.1]
  def change
    add_column :request_stats, :error_sample, :string, limit: 500, after: :server_errors
  end
end
