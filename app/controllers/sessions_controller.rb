# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :require_authentication, only: :destroy
  rate_limit to: 10, within: 3.minutes, only: :create, with: lambda {
    redirect_to new_session_url, alert: 'Try again later.'
  }

  def new; end

  def create
    user = User.authenticate_by(params.permit(:email, :password))

    if user.present?
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: 'Try another email address or password.'
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  def omniauth_failure
    redirect_to new_session_path, alert: 'Authentication failed. Please try again.'
  end
end
