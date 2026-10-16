# frozen_string_literal: true

module Searchkick
  # One searchable model at a time so a monthly full reindex does not hold Action Text for
  # Fiction + Publication + YoutubeVideo in one process peak.
  class SyncSoftDeletableModelJob < ApplicationJob
    queue_as :searchkick

    def perform(model_name)
      return unless Rails.env.production?

      model = SyncSoftDeletable::MODELS.find { |entry| entry.name == model_name }
      raise ArgumentError, "unknown searchable model: #{model_name}" unless model

      SyncSoftDeletable.new(full_reindex: true).sync_model(model)
    end
  end
end
