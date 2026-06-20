# frozen_string_literal: true

# Turbo Stream helpers for layout flash frames (application-notice / application-alert).
module TurboFlashStream
  extend ActiveSupport::Concern

  private

  def turbo_stream_notice(message)
    [
      turbo_stream.update('application-notice', partial: 'shared/notice', locals: { notice: message }),
      turbo_stream.update('application-alert', html: '')
    ]
  end

  def turbo_stream_alert(message)
    [
      turbo_stream.update('application-alert', partial: 'shared/alert', locals: { alert: message }),
      turbo_stream.update('application-notice', html: '')
    ]
  end

  def turbo_stream_clear_flash_frames
    [
      turbo_stream.update('application-notice', html: ''),
      turbo_stream.update('application-alert', html: '')
    ]
  end
end
