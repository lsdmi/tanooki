# frozen_string_literal: true

class PublishScheduledChaptersJob < ApplicationJob
  queue_as :default

  def perform
    chapters = Chapter.scheduled_ready
    return if chapters.none?

    chapters.find_each do |chapter|
      chapter.update_column(:publish_at, nil)
      clear_fiction_cache(chapter.fiction)
      Rails.logger.info "Published scheduled chapter ##{chapter.id} (#{chapter.display_title})"
    end
  end

  private

  def clear_fiction_cache(fiction)
    max_updated_at = fiction.chapters.maximum(:updated_at) || fiction.updated_at
    Rails.cache.delete("duplicate_chapters/#{fiction.id}/#{max_updated_at}")
  end
end
