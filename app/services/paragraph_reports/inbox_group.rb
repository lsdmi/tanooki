# frozen_string_literal: true

module ParagraphReports
  # One Studio card for every open report that shares chapter + reader block + digest.
  class InboxGroup
    attr_reader :reports

    def self.from_reports(reports)
      list = Array(reports)
      raise ArgumentError, 'reports required' if list.empty?

      new(list)
    end

    def initialize(reports)
      @reports = reports.sort_by(&:created_at).reverse
    end

    def primary = reports.first

    delegate :chapter, :quote, :block_index, :digest, :created_at, to: :primary
    delegate :size, to: :reports

    def report_ids = reports.map(&:id)

    def reporters = reports.map(&:user).uniq

    def messages = reports.filter_map { |report| report.message.presence }.uniq
  end
end
