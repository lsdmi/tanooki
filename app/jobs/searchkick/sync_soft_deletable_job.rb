# frozen_string_literal: true

module Searchkick
  # OpenSearch maintenance for Fiction, Publication, and YoutubeVideo.
  # Weekly: soft-delete cleanup only. Monthly: optional full reindex (batched) at a quiet hour.
  class SyncSoftDeletableJob < ApplicationJob
    queue_as :searchkick

    # Positional string so recurring.yml can pass `args: [full_reindex]` (same shape as TelegramDigests::PostJob).
    def perform(mode = 'cleanup')
      return unless Rails.env.production?

      case mode.to_s
      when 'cleanup'
        SyncSoftDeletable.new(full_reindex: false).call
      when 'full_reindex'
        enqueue_per_model_full_reindex
      else
        raise ArgumentError, "unknown mode: #{mode}"
      end
    end

    private

    def enqueue_per_model_full_reindex
      SyncSoftDeletable::MODELS.each_with_index do |model, index|
        SyncSoftDeletableModelJob.set(wait: index * 2.minutes).perform_later(model.name)
      end
    end
  end
end
