# frozen_string_literal: true

module Chapters
  # Resolves one or many open paragraph reports (Studio dedup card = same chapter/block/digest).
  class ResolveParagraphReports
    Result = Data.define(:ok, :reports, :error, :status)

    def self.call(...) = new(...).call

    def initialize(reports:, user:, status:)
      @reports = Array(reports)
      @user = user
      @status = status
    end

    def call
      return failure(:invalid_transition) if @reports.empty?

      resolved = []
      @reports.each do |report|
        result = ResolveParagraphReport.call(report:, user: @user, status: @status)
        return failure(result.error) unless result.ok

        resolved << result.report
      end

      Result.new(ok: true, reports: resolved, error: nil, status: resolved.first.status)
    end

    private

    def failure(error) = Result.new(ok: false, reports: [], error:, status: nil)
  end
end
