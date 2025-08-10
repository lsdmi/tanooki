# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
    helper_method :authenticated?
  end

  private

  def authenticated?
    resume_session
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    clear_devise_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    session_id = cookies.signed[:session_id] || cookies[:session_id]
    Session.find_by(id: session_id) if session_id
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_path
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || root_url
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
    end
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:session_id)
  end

  def clear_devise_session
    return unless session['warden.user.user.key'].presence || cookies.signed['remember_user_token'].presence

    session.delete('warden.user.user.key')
    cookies.delete('remember_user_token')
  end
end
