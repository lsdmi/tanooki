# frozen_string_literal: true

# Lazy navbar chrome: unread comment badge for the notifications menu item.
class NotificationBadgesController < ApplicationController
  before_action :authenticate_user!

  def show
    render layout: false
  end
end
