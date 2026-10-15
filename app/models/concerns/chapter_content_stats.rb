# frozen_string_literal: true

# Keeps chapters.word_count / body_bytes / excerpt in sync when Action Text is loaded for the save.
module ChapterContentStats
  extend ActiveSupport::Concern

  included do
    before_save :refresh_content_stats, if: :content_loaded?
  end

  # Unloaded means untouched this save; checking must not load the body.
  def content_loaded?
    association(:rich_text_content).loaded?
  end

  private

  def refresh_content_stats
    assign_attributes(Chapters::ContentStats.attributes_for(self))
  end
end
