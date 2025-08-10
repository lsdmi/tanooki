# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private

    def set_current_user
      session = Session.find_by(id: cookies.signed[:session_id])

      return nil unless session

      self.current_user = session.user
    end
  end
end
