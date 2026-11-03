# frozen_string_literal: true

# Contest participation links on a fiction; soft-delete withdraws open entries.
module FictionContestEntries
  extend ActiveSupport::Concern

  included do
    # Soft-delete runs destroy callbacks, so AR :dependent would destroy/nullify/restrict
    # entries on soft delete. Withdraw instead; hard delete cascades via the FK.
    has_many :contest_entries, inverse_of: :fiction

    after_destroy :withdraw_contest_entries_on_soft_delete
  end

  def withdraw_contest_entries_on_soft_delete
    contest_entries.find_each do |entry|
      next if entry.withdrawn?
      next if entry.contest.results_published?

      Contests::WithdrawEntry.call(entry:, system: true)
    end
  end
end
