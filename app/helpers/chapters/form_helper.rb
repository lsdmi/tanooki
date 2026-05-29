# frozen_string_literal: true

module Chapters
  # Chapter form fields and display labels.
  module FormHelper
    HALF_HOUR_MINUTES = [0, 30].freeze

    delegate :format_decimal, to: :'Chapters::Formatting'

    def title_includes_rozdil?(title)
      return true if title.blank?

      title.match?(/Розділ/i)
    end

    # Half-hour slots 00:00–23:30 (24h labels). Includes +selected+ if it is not on the grid (legacy data).
    def chapter_publish_time_select_options(selected = nil)
      slots = (0..23).flat_map do |h|
        HALF_HOUR_MINUTES.map { |m| format('%<hour>02d:%<minute>02d', hour: h, minute: m) }
      end
      options = slots.map { |t| [t, t] }
      options.unshift([selected, selected]) if selected.present? && slots.exclude?(selected)
      options
    end
  end
end
