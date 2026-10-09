# frozen_string_literal: true

module Api
  module Mcp
    # Shared tool annotations. A destructive hint is only for publish and revert.
    module Hints
      def read_only
        annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)
      end

      def writes(destructive: false)
        annotations(
          read_only_hint: false, destructive_hint: destructive, idempotent_hint: false, open_world_hint: false
        )
      end
    end
  end
end
