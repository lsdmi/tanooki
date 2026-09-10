# frozen_string_literal: true

# Stores which listing nudges a team dismissed (keyed by kind, value is the snapshot that was skipped).
class AddListingNudgeDismissalsToFictions < ActiveRecord::Migration[8.1]
  def change
    add_column :fictions, :listing_nudge_dismissals, :json, after: :last_chapter_at
  end
end
