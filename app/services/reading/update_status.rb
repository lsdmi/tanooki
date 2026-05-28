# frozen_string_literal: true

module Reading
  # Updates or destroys a reading progress record and invalidates related caches.
  class UpdateStatus
    DESTROY_STATUS = 'destroy'
    ALLOWED_STATUSES = (ReadingProgress.statuses.keys + [DESTROY_STATUS]).freeze

    def self.allowed_status?(status)
      normalize_status(status).present?
    end

    def self.normalize_status(status, default: nil)
      key = status.to_s.presence || default
      return nil if key.nil?

      ALLOWED_STATUSES.include?(key) ? key : nil
    end

    def initialize(reading_progress, new_status, user)
      @reading_progress = reading_progress
      @new_status = new_status
      @user = user
    end

    def call
      status = self.class.normalize_status(@new_status)
      return invalid_status_outcome unless status

      apply_status_change(status)
      Outcomes::OperationOutcome.new(success: true, data: { reading_progress: @reading_progress })
    end

    private

    def apply_status_change(status)
      ActiveRecord::Base.transaction do
        if status == DESTROY_STATUS
          @reading_progress.destroy!
        else
          @reading_progress.update!(status: status)
        end
        clear_caches
        @reading_progress.reload unless @reading_progress.destroyed?
      end
    end

    def invalid_status_outcome
      Outcomes::OperationOutcome.new(success: false, data: { reading_progress: @reading_progress })
    end

    def clear_caches
      Reading::ProgressCacheInvalidation.new(@user, @reading_progress.fiction).clear
    end
  end
end
