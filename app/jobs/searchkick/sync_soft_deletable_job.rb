# frozen_string_literal: true

module Searchkick
  # Weekly OpenSearch maintenance for Fiction, Publication, and YoutubeVideo indexes.
  class SyncSoftDeletableJob < ApplicationJob
    queue_as :default

    def perform
      return unless Rails.env.production?

      SyncSoftDeletable.new.call
    end
  end
end
