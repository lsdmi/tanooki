# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  helper_method :trending_tags

  private

  def trending_tags
    TrendingTagsService.call
  end

  def track_visit
    return if session[:viewed_publications]&.include?(@publication.id)

    @publication.increment!(:views)
    session[:viewed_publications] ||= []
    session[:viewed_publications] << @publication.id
  end

  def verify_user_permissions
    redirect_to root_path unless current_user.admin?
  end
end
