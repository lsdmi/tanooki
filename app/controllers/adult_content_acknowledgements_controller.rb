# frozen_string_literal: true

# Records that the visitor acknowledged the adult-content notice.
class AdultContentAcknowledgementsController < ApplicationController
  def create
    if user_signed_in?
      current_user.update!(adult_content_acknowledged_at: Time.zone.today)
    else
      session[:adult_content_ack] = true
    end

    head :no_content
  end
end
