# frozen_string_literal: true

module Fictions
  class Merge
    # Chapter projections, summed views, completion, and blank titles on the surviving fiction.
    class Listing
      def initialize(source:, target:, report:)
        @source = source
        @target = target
        @report = report
      end

      def call
        Catalog::RefreshChapterStats.call(@target)
        transfer_views
        fill_titles
        @target.completed_at = later_completion
        @target.save!(validate: false)
      end

      private

      def transfer_views
        added = @source.views.to_i
        @target.views = @target.views.to_i + added
        @report.count(:views, added)
      end

      # The surviving page keeps its own completion. A finished source must not
      # mark an ongoing translation as finished.
      def later_completion
        return if @target.completed_at.nil?

        [@source.completed_at, @target.completed_at].compact.max
      end

      def fill_titles
        filled = [copy(:english_title), copy(:alternative_title), ukrainian_title].compact
        @report.titles(filled)
      end

      def copy(field)
        return if @target.public_send(field).present?
        return if @source.public_send(field).blank?

        @target.public_send(:"#{field}=", @source.public_send(field))
        field.to_s
      end

      def ukrainian_title
        return if @target.alternative_title.present?
        return if @source.title == @target.title

        @target.alternative_title = @source.title
        'ukrainian_title'
      end
    end
  end
end
