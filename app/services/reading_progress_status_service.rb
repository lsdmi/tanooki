# frozen_string_literal: true

class ReadingProgressStatusService
  def initialize(reading_progress, new_status, user)
    @reading_progress = reading_progress
    @new_status = new_status
    @user = user
  end

  def call
    ActiveRecord::Base.transaction do
      if @new_status == :destroy || @new_status == 'destroy'
        @reading_progress.destroy!
      else
        @reading_progress.update!(status: @new_status)
      end
      clear_caches
      @reading_progress.reload unless @reading_progress.destroyed?
    end
  end

  private

  def clear_caches
    CacheClearer.new(@user, @reading_progress.fiction).clear_reading_caches
  end
end
