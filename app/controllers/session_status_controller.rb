# frozen_string_literal: true

# Lightweight JSON endpoint for client-side session watchdog checks.
class SessionStatusController < ApplicationController
  def show
    render json: { authenticated: user_signed_in? }
  end
end
