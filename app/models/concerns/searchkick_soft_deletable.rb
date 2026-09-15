# frozen_string_literal: true

# Keeps Searchkick indexes aligned with SoftDeletable (and Draftable): rows that
# should not be searchable are removed from OpenSearch.
module SearchkickSoftDeletable
  extend ActiveSupport::Concern

  ACTIVE_WHERE = { active: true }.freeze

  class_methods do
    def searchkick_active_where
      ACTIVE_WHERE
    end
  end

  included do
    after_commit :remove_from_search_index_when_not_indexable, on: :update
    after_real_destroy :remove_from_search_index_after_hard_destroy
  end

  def should_index?
    deleted_at.nil?
  end

  private

  def remove_from_search_index_when_not_indexable
    return if should_index?
    return unless unindexable_attribute_changed?

    safely_remove_from_search_index
  end

  def unindexable_attribute_changed?
    saved_change_to_deleted_at? || (has_attribute?(:status) && saved_change_to_status?)
  end

  def remove_from_search_index_after_hard_destroy
    safely_remove_from_search_index
  end

  def safely_remove_from_search_index
    self.class.searchkick_index.remove(self)
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Errno::ECONNREFUSED => e
    Rails.logger.warn("[searchkick] failed to remove #{self.class.name} #{id} from index: #{e.message}")
  end
end
