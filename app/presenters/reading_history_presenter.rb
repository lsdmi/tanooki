# frozen_string_literal: true

class ReadingHistoryPresenter
  attr_reader :readings

  def initialize(readings, chapter_fetcher: ->(fiction) { fiction.chapters.released.order(created_at: :desc).first })
    @readings = readings
    @grouper = ReadingHistoryGrouper.new(readings, chapter_fetcher: chapter_fetcher)
    @grouped = @grouper.group
  end

  def section(name = :active)
    @grouped[name.to_sym] || []
  end

  private

  def ordered_chapters_desc(fiction)
    fiction.chapters.released.order(created_at: :desc)
  end
end
