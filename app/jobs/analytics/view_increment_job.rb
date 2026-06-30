# frozen_string_literal: true

module Analytics
  # Persists a single view count increment off the request path (fiction/chapter show TTFB).
  class ViewIncrementJob < ApplicationJob
    queue_as :default

    def perform(class_name, record_id)
      record = class_name.constantize.find_by(id: record_id)
      return unless record

      record.with_lock do
        record.update!(views: record.views + 1)
      end
    end
  end
end
