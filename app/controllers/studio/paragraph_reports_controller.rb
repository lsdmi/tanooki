# frozen_string_literal: true

module Studio
  # Resolve open paragraph error reports from the Studio notifications inbox.
  class ParagraphReportsController < ApplicationController
    ERROR_FLASH = {
      forbidden: :alert,
      already_resolved: :alert,
      invalid_transition: :alert
    }.freeze

    before_action :authenticate_user!

    def update
      result = Chapters::ResolveParagraphReports.call(
        reports: reports_to_resolve, user: current_user, status: params.expect(:status)
      )
      return redirect_resolved(result.error) unless result.ok

      redirect_to studio_index_path(tab: 'notifications'),
                  notice: resolve_notice(result)
    end

    private

    def reports_to_resolve
      ids = Array(params[:ids]).presence || [params.expect(:id)]
      ParagraphReport.includes(:chapter).where(id: ids).to_a
    end

    def resolve_notice(result)
      count = result.reports.size
      if count > 1
        t("studio.paragraph_reports.resolved_many.#{result.status}", count:)
      else
        t("studio.paragraph_reports.resolved.#{result.status}")
      end
    end

    def redirect_resolved(error)
      redirect_to studio_index_path(tab: 'notifications'),
                  ERROR_FLASH.fetch(error) => t("studio.paragraph_reports.errors.#{error}")
    end
  end
end
