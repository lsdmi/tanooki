# frozen_string_literal: true

class FictionStatusTracker
  include LibraryHelper

  attr_reader :fiction_status, :total_chapters, :unique

  def initialize(fiction)
    @fiction_status = fiction.status
    @total_chapters = fiction.total_chapters
    @unique = unique_chapters(fiction.chapters)
  end

  def call
    new_fiction_status
  end

  private

  def announced_dropped_new_status
    unique.size >= total_chapters ? Fiction.statuses[:finished] : Fiction.statuses[:ongoing]
  end

  def ongoing_new_status
    unique.size >= total_chapters ? Fiction.statuses[:finished] : fiction_status
  end

  def new_fiction_status
    case Fiction.statuses[fiction_status]
    when Fiction.statuses[:announced], Fiction.statuses[:dropped]
      announced_dropped_new_status
    when Fiction.statuses[:ongoing]
      ongoing_new_status
    else
      fiction_status
    end
  end
end
