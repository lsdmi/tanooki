# frozen_string_literal: true

# Appends session flash to turbo_stream responses when the controller did not set layout flash frames.
module TurboFlashStreamResponse
  extend ActiveSupport::Concern

  included do
    after_action :append_session_flash_to_turbo_stream, if: :append_session_flash_to_turbo_stream?
  end

  private

  def append_session_flash_to_turbo_stream?
    response.media_type == Mime[:turbo_stream].to_s &&
      response.successful? &&
      (flash[:notice].present? || flash[:alert].present?)
  end

  def append_session_flash_to_turbo_stream
    return if response.body.include?('target="application-notice"')

    self.response_body = session_flash_streams.map(&:to_s).join + response.body
  end

  def session_flash_streams
    flash[:notice].present? ? turbo_stream_notice(flash[:notice]) : turbo_stream_alert(flash[:alert])
  end
end
