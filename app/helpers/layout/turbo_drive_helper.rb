# frozen_string_literal: true

module Layout
  # Turbo Drive link attributes for full-page visits (escape frames, optional preload).
  module TurboDriveHelper
    def turbo_drive_visit_data(preload: false)
      data = { turbo_frame: '_top' }
      data[:turbo_preload] = true if preload

      { data: data }
    end
  end
end
