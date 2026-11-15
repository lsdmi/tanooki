# frozen_string_literal: true

module ParagraphReports
  # Open paragraph error reports for Studio: team chapters for members, all open for admins.
  # Studio cards are grouped by chapter + block_index + digest so duplicate reader signals share one row.
  class InboxCollector
    def initialize(user)
      @user = user
    end

    def call
      relation.preload({ user: { avatar: :image_attachment } }, { chapter: :fiction })
              .order(created_at: :desc)
    end

    def groups
      call.to_a
          .group_by { |report| [report.chapter_id, report.block_index, report.digest] }
          .values
          .map { |reports| InboxGroup.from_reports(reports) }
          .sort_by { |group| -group.created_at.to_i }
    end

    def open_count
      relation.count
    end

    private

    attr_reader :user

    def relation
      scope = ParagraphReport.open
      return scope if user.admin?

      scope.for_scanlator_ids(user.scanlators.select(:id))
    end
  end
end
