# frozen_string_literal: true

module Fictions
  # Updates dropped status for unfinished fictions (was VPS cron Sunday).
  class RefreshDroppedStatusJob < ApplicationJob
    queue_as :default

    def perform
      return unless Rails.env.production?

      Fiction.find_each do |fiction|
        fiction.set_dropped_status unless fiction.finished?
      end
    end
  end
end
