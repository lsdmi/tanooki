# frozen_string_literal: true

# One row per job class per hour from the Solid Queue worker, so job volume, failures and queue wait outlive the
# worker's logs, which every deploy wipes.
class CreateJobStats < ActiveRecord::Migration[8.1]
  def change
    create_table :job_stats do |t|
      t.datetime :period_start, null: false
      t.string :job_class, null: false
      t.integer :jobs, :failures, null: false
      t.float :duration_ms_sum, :duration_ms_max, :wait_ms_sum, :wait_ms_max, null: false
      t.string :error_sample, limit: 500
      t.datetime :created_at, null: false
      t.index %i[period_start job_class]
    end
  end
end
