# frozen_string_literal: true

module Layout
  # Turbo Drive link attributes for browse navigation and frame escapes.
  module TurboDriveHelper
    def session_watchdog_stimulus_data
      {
        controller: 'session-watchdog',
        session_watchdog_status_url_value: session_status_path,
        session_watchdog_diagnostics_url_value: session_diagnostics_path,
        session_watchdog_login_url_value: new_user_session_path
      }
    end

    def turbo_drive_visit_data(preload: false, frame: '_top')
      return turbo_browse_link_data(preload: preload) if frame.nil?

      data = { turbo_frame: frame }
      data[:turbo_preload] = true if preload

      { data: data }
    end

    def turbo_browse_link_data(preload: false)
      data = preload ? { turbo_preload: true } : {}

      { data: data }
    end
  end
end
