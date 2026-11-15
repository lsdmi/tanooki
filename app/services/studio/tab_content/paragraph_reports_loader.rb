# frozen_string_literal: true

module Studio
  class TabContent
    # Studio → Сповіщення: open paragraph-error groups for the current user.
    module ParagraphReportsLoader
      private

      def open_report_counts_by_fiction(fictions)
        ids = fictions.map(&:id)
        return {} if ids.empty?

        ParagraphReport.open.joins(:chapter)
                       .where(chapters: { fiction_id: ids })
                       .group('chapters.fiction_id')
                       .count
      end

      def load_paragraph_report_groups
        return clear_paragraph_report_groups unless ParagraphReportsAccess.allowed?(user)

        @reports_pagy, @paragraph_report_groups = pagy_array(
          ParagraphReports::InboxCollector.new(user).groups,
          limit: 4,
          page_param: :reports_page
        )
        @paragraph_report_digests = current_digests_for(@paragraph_report_groups.map(&:chapter))
      end

      def clear_paragraph_report_groups
        @paragraph_report_groups = []
        @paragraph_report_digests = {}
        @reports_pagy = nil
      end

      def current_digests_for(chapters)
        chapters = chapters.uniq
        ActiveRecord::Associations::Preloader.new(records: chapters, associations: :rich_text_content).call
        chapters.to_h { |chapter| [chapter.id, Chapters::ReaderContentHtml.new(chapter).digest] }
      end
    end
  end
end
