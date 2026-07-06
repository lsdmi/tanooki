# frozen_string_literal: true

# Receives client-side reports when a protected page loses its session.
class SessionDiagnosticsController < ApplicationController
  rate_limit to: 20, within: 1.minute, only: :create

  def create
    SessionDiagnostics::Logger.log_client_report(
      request,
      reason: params[:reason],
      page_url: params[:page_url]
    )

    head :no_content
  end
end
