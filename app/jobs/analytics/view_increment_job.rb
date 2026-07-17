# frozen_string_literal: true

module Analytics
  # Persists a single view count increment off the request path (fiction/chapter show TTFB).
  class ViewIncrementJob < ApplicationJob
    queue_as :default

    def perform(class_name, record_id)
      klass = class_name.constantize
      return unless klass.exists?(id: record_id)

      klass.where(id: record_id).update_all('views = COALESCE(views, 0) + 1') # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
