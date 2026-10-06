# frozen_string_literal: true

# Official Ukrainian license: when it was recorded, who publishes it and where to buy.
class AddLicenseToFictions < ActiveRecord::Migration[8.1]
  def change
    change_table :fictions, bulk: true do |t|
      t.datetime :licensed_at, after: :completed_at
      t.string :license_publisher, limit: 100, after: :licensed_at
      t.string :license_url, limit: 500, after: :license_publisher
      t.index :licensed_at
    end
  end
end
