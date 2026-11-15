# frozen_string_literal: true

module Chapters
  # Closes an open paragraph error report as fixed or dismissed. Team members and admins only.
  class ResolveParagraphReport
    Result = Data.define(:ok, :report, :error)

    ALLOWED = {
      'fixed' => :fixed,
      'dismissed' => :dismissed
    }.freeze

    def self.call(...) = new(...).call

    def initialize(report:, user:, status:)
      @report = report
      @user = user
      @status = status
    end

    def call
      return failure(:forbidden) unless @user.manages_chapter?(@report.chapter)
      return failure(:already_resolved) unless @report.open?

      next_status = ALLOWED[@status.to_s]
      return failure(:invalid_transition) unless next_status

      @report.update!(status: next_status, resolved_by: @user, resolved_at: Time.current)
      success(@report)
    end

    private

    def success(report) = Result.new(ok: true, report:, error: nil)

    def failure(error) = Result.new(ok: false, report: nil, error:)
  end
end
