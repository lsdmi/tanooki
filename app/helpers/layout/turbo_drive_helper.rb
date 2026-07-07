# frozen_string_literal: true

module Layout
  # Turbo Drive link attributes for browse navigation and frame escapes.
  module TurboDriveHelper
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
