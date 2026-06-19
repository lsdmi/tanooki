# frozen_string_literal: true

# Keeps Searchkick indexes aligned with acts_as_paranoid: soft-deleted rows are removed
# from OpenSearch and indexed documents carry `active: true` for query filtering.
module SearchkickSoftDeletable
  extend ActiveSupport::Concern

  ACTIVE_WHERE = { active: true }.freeze

  class_methods do
    def searchkick_active_where
      ACTIVE_WHERE
    end
  end

  included do
    after_commit :remove_from_search_index_after_soft_delete, on: :update
    after_real_destroy :remove_from_search_index_after_hard_destroy
  end

  def should_index?
    deleted_at.nil?
  end

  private

  def remove_from_search_index_after_soft_delete
    return unless saved_change_to_deleted_at? && deleted?

    self.class.searchkick_index.remove(self)
  end

  def remove_from_search_index_after_hard_destroy
    self.class.searchkick_index.remove(self)
  end
end
