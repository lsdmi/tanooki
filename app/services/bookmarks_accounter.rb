# frozen_string_literal: true

# Counts active, finished, postponed, and dropped readings for a fiction.
class BookmarksAccounter
  include Library::ReadingStateHelper

  attr_reader :fiction

  def initialize(fiction:)
    @fiction = fiction
  end

  def call
    [active, finished, postponed, dropped]
  end

  private

  def active
    fiction.readings.active.count
  end

  def finished
    fiction.readings.finished.count
  end

  def postponed
    fiction.readings.postponed.count
  end

  def dropped
    fiction.readings.dropped.count
  end
end
