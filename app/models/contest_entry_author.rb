# frozen_string_literal: true

# Snapshot of who authored a contest entry (for badges after team changes).
class ContestEntryAuthor < ApplicationRecord
  belongs_to :contest_entry, inverse_of: :entry_authors
  belongs_to :user

  validates :user_id, uniqueness: { scope: :contest_entry_id }
end
