# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :authenticate_user!, :latest_comments

  def notifications
    @pagy, @comments = pagy(my_comments, limit: 8)

    current_user.update(latest_read_comment_id: latest_comments.first&.id)
    render 'users/show'
  end

  private

  def my_comments
    Comment.where(id: latest_comments.pluck(:id)).order(id: :desc)
  end
end
