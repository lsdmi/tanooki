# frozen_string_literal: true

module Fictions
  class Merge
    # One row per user: move source-only rows, and when both exist keep the one updated last.
    class UniqueRows
      def initialize(model, source_id:, target_id:)
        @model = model
        @source_id = source_id
        @target_id = target_id
        @moved = 0
        @kept = 0
        @removed = 0
      end

      def call
        @model.where(fiction_id: @source_id).to_a.each { |row| keep(row) }
        { moved: @moved, kept: @kept, removed: @removed }
      end

      private

      def keep(row)
        other = @model.find_by(fiction_id: @target_id, user_id: row.user_id)
        other.nil? ? move(row) : prefer_newer(row, other)
      end

      def prefer_newer(row, other)
        if row.updated_at > other.updated_at
          drop(other)
          relocate(row)
        else
          drop(row)
        end
        @kept += 1
      end

      def move(row)
        relocate(row)
        @moved += 1
      end

      def relocate(row)
        row.update!(fiction_id: @target_id)
      end

      def drop(row)
        row.destroy!
        @removed += 1
      end
    end
  end
end
