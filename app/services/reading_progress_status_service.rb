# frozen_string_literal: true

class ReadingProgressStatusService
  def initialize(reading_progress, new_status, user)
    @reading_progress = reading_progress
    @new_status = new_status
    @user = user
  end

  def call
    ActiveRecord::Base.transaction do
      @reading_progress.update!(status: @new_status)
      clear_caches
      @reading_progress.reload
    end
  end

  private

  def clear_caches
    CacheClearer.new(@user, @reading_progress.fiction).clear_reading_caches
  end
end
