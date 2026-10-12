# frozen_string_literal: true

module Library
  # Loads the chapter lists and read sets behind one /library page in two queries, ahead of the rows' presenters,
  # under the RequestMemo keys ChapterCatalog.listed_chapters and Reading::ReadKeys look up.
  # Lists with their own rules load as before: an admin's, a licensed work's, and a work the viewer's team scanlates.
  class EntryPreload
    def self.call(readings, viewer:)
      new(readings, viewer:).call
    end

    def initialize(readings, viewer:)
      @fictions = readings.map(&:fiction).uniq
      @viewer = viewer
    end

    def call
      return if @fictions.empty?

      store_listed_chapters
      store_read_keys
    end

    private

    def store_listed_chapters
      ids = plain_list_fiction_ids
      return if ids.empty?

      chapters = Chapter.where(fiction_id: ids)
                        .where(ChapterCatalog.visible_to_everyone_sql_fragment, Time.current)
                        .order(ChapterCatalog.order_clause_desc).group_by(&:fiction_id)
      ids.each { |id| RequestMemo.store(:listed_chapters, id, @viewer.id, true, chapters.fetch(id, []).freeze) }
    end

    def plain_list_fiction_ids
      return [] if @viewer.admin?

      team_ids = ChapterCatalog.viewer_scanlator_ids(@viewer)
      @fictions.reject { |fiction| fiction.licensed? || team_ids.intersect?(fiction.scanlators.map(&:id)) }
               .map(&:id)
    end

    def store_read_keys
      keys = ReadingChapterRead.where(user: @viewer, fiction_id: @fictions.map(&:id))
                               .joins('INNER JOIN chapters ON chapters.id = reading_chapter_reads.chapter_id')
                               .pluck(:fiction_id, 'chapters.volume_number', 'chapters.number')
                               .group_by(&:first)
      @fictions.each do |fiction|
        RequestMemo.store(:read_keys, @viewer.id, fiction.id, keys.fetch(fiction.id, []).to_set { |row| row.drop(1) })
      end
    end
  end
end
