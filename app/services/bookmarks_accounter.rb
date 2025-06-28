# frozen_string_literal: true

class BookmarksAccounter
  include LibraryHelper

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
