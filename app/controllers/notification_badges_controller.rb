# frozen_string_literal: true

# Lazy navbar chrome: badge for unread comments and open paragraph-error reports.
class NotificationBadgesController < ApplicationController
  before_action :authenticate_user!

  def show
    render layout: false
  end
end
