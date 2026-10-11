# frozen_string_literal: true

module Fictions
  class Merge
    # Retargets child rows and drops unique-index duplicates before they are moved.
    class Rows
      Tally = Struct.new(:moved, :skipped) do
        def initialize
          super(0, 0)
        end
      end

      def initialize(source:, target:, report:)
        @source = source
        @target = target
        @report = report
      end

      def call
        count_retarget(Chapter, :chapters)
        count_retarget(ReadingChapterRead, :reading_chapter_reads)
        conflicts(ReadingProgress, :reading_progresses)
        conflicts(FictionRating, :fiction_ratings)
        @report.skipped(:bookshelf_fictions, **dedupe(BookshelfFiction, :bookshelf_id))
        @report.skipped(:fiction_genres, **dedupe(FictionGenre, :genre_id))
        scanlators
        comments
      end

      private

      def count_retarget(model, label)
        @report.count(label, retarget(model.table_name))
      end

      def conflicts(model, label)
        @report.conflicts(label, **UniqueRows.new(model, source_id: @source.id, target_id: @target.id).call)
      end

      def retarget(table)
        connection.update(<<~SQL.squish)
          UPDATE #{connection.quote_table_name(table)}
          SET fiction_id = #{Integer(@target.id)}
          WHERE fiction_id = #{Integer(@source.id)}
        SQL
      end

      def dedupe(model, key)
        tally = Tally.new
        seen = model.where(fiction_id: @target.id).pluck(key)
        model.where(fiction_id: @source.id).find_each { |row| place(row, key, seen, tally) }
        { moved: tally.moved, skipped: tally.skipped }
      end

      def place(row, key, seen, tally)
        return skip(row, tally) if seen.include?(row.public_send(key))

        row.update!(fiction_id: @target.id)
        seen << row.public_send(key)
        tally.moved += 1
      end

      def skip(row, tally)
        row.destroy!
        tally.skipped += 1
      end

      def scanlators
        ids = FictionScanlator.where(fiction_id: [@source.id, @target.id]).distinct.pluck(:scanlator_id)
        @report.skipped(:fiction_scanlators, **dedupe(FictionScanlator, :scanlator_id))
        ids.each { |id| refresh_count(id) }
      end

      def refresh_count(scanlator_id)
        scanlator = Scanlator.find(scanlator_id)
        scanlator.fictions_count = scanlator.fiction_scanlators.joins(:fiction).count
        scanlator.save!(validate: false)
      end

      def comments
        @report.count(:comments, retarget_comments)
        @target.comments_count = Comment.where(commentable: @target).count
        @source.comments_count = 0
      end

      def retarget_comments
        connection.update(<<~SQL.squish)
          UPDATE comments
          SET commentable_id = #{Integer(@target.id)}
          WHERE commentable_type = #{connection.quote(Fiction.name)}
            AND commentable_id = #{Integer(@source.id)}
        SQL
      end

      def connection
        Fiction.lease_connection
      end
    end
  end
end
