# frozen_string_literal: true

# Rights holder takedown of a licensed work: when an admin hid every chapter past the preview.
class AddChaptersHiddenAtToFictions < ActiveRecord::Migration[8.1]
  def change
    add_column :fictions, :chapters_hidden_at, :datetime, after: :license_url
  end
end
