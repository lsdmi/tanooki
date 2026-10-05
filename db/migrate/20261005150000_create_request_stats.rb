# frozen_string_literal: true

# Hourly per-action request timings written by Analytics::RequestStats. A restart mid-hour leaves two rows for that
# hour and action: sums add up, percentiles do not.
class CreateRequestStats < ActiveRecord::Migration[8.1]
  def change
    create_table :request_stats do |t|
      t.datetime :period_start, null: false
      t.string :endpoint, null: false
      t.integer :requests, null: false
      t.integer :server_errors, null: false
      t.float :duration_ms_sum, null: false
      t.float :duration_ms_p50, null: false
      t.float :duration_ms_p95, null: false
      t.float :duration_ms_max, null: false
      t.float :db_ms_sum, null: false
      t.float :db_ms_p95, null: false
      t.float :view_ms_sum, null: false
      t.float :view_ms_p95, null: false
      t.integer :queries_sum, null: false
      t.integer :queries_p95, null: false
      t.bigint :bytes_sum, null: false
      t.integer :bytes_p95, null: false
      t.datetime :created_at, null: false
    end
    add_index :request_stats, %i[period_start endpoint]
  end
end
