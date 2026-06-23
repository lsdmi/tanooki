# frozen_string_literal: true

# Local soft-delete behavior (replaces the paranoia gem).
# Sets deleted_at on destroy; use really_destroy! for hard deletes.
module SoftDeletable
  extend ActiveSupport::Concern

  include Associations

  included do
    define_model_callbacks :real_destroy

    default_scope -> { where(deleted_at: nil) }

    alias_method :destroy_without_soft_delete, :destroy

    define_method(:destroy) { soft_delete || false }
    define_method(:destroy!) do
      soft_delete || raise(ActiveRecord::RecordNotDestroyed.new('Failed to destroy the record', self))
    end
    define_method(:delete) do
      soft_delete_attributes_update
      self
    end
  end

  class_methods do
    def soft_deletable?
      true
    end

    def with_deleted
      unscope(where: :deleted_at)
    end

    def only_deleted
      with_deleted.where.not(deleted_at: nil)
    end

    def without_deleted
      where(deleted_at: nil)
    end
  end

  def soft_deletable?
    true
  end

  def deleted?
    deleted_at.present?
  end

  def really_destroy!
    with_transaction_returning_status do
      run_callbacks(:real_destroy) do
        really_destroy_soft_deletable_associations
        destroy_without_soft_delete
      end
    end
  end

  def trigger_transactional_callbacks?
    super || (@_trigger_destroy_callback && deleted?)
  end

  private

  def soft_delete
    with_transaction_returning_status do
      result = run_callbacks(:destroy) do
        result = soft_delete_attributes_update
        @_trigger_destroy_callback = true
        result
      end
      raise ActiveRecord::Rollback, 'Not destroyed' unless deleted?

      result
    end
  end

  def soft_delete_attributes_update
    raise ActiveRecord::ReadOnlyRecord, "#{self.class} is marked as readonly" if readonly?

    if persisted?
      add_to_transaction
      update_columns(soft_delete_attributes)
    elsif !frozen?
      assign_attributes(soft_delete_attributes)
    end

    true
  end

  def soft_delete_attributes
    { deleted_at: current_time_from_proper_timezone }.merge(timestamp_attributes_for_update_in_model.index_with do
      current_time_from_proper_timezone
    end)
  end
end
