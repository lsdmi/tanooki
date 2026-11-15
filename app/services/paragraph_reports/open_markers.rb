# frozen_string_literal: true

module ParagraphReports
  # Public reader marks for open paragraph reports whose digest still matches the live
  # chapter body. Each marker carries reader messages (+ name) for click/hover.
  class OpenMarkers
    def self.for(chapter)
      new(chapter).markers
    end

    def self.block_indices_for(chapter)
      self.for(chapter).pluck(:i)
    end

    def initialize(chapter)
      @chapter = chapter
    end

    def markers
      return [] if chapter.blank? || chapter.license_hidden?

      matching_reports.group_by(&:block_index).sort.map { |index, group| marker_payload(index, group) }
    end

    private

    attr_reader :chapter

    def matching_reports
      ParagraphReport.open
                     .includes(:user)
                     .where(chapter_id: chapter.id, digest: Chapters::ReaderContentHtml.new(chapter).digest)
                     .order(:created_at)
                     .to_a
    end

    def marker_payload(block_index, group)
      {
        i: block_index,
        m: group.map { |report| { u: report.user.name, t: report.message.to_s, q: report.quote.to_s } }
      }
    end
  end
end
