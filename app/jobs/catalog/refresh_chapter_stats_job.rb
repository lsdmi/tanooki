# frozen_string_literal: true

module Catalog
  # Refreshes a fiction's listing projections when a scheduled chapter goes live (enqueued by Chapters::Persist),
  # since last_chapter_at only counts chapters that are already public.
  class RefreshChapterStatsJob < ApplicationJob
    queue_as :default
    discard_on ActiveRecord::RecordNotFound

    def perform(fiction_id)
      RefreshChapterStats.call(Fiction.find(fiction_id))
    end
  end
end
