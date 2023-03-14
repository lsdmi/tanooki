# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  private

  def track_visit
    return if session[:viewed_publications]&.include?(@publication.id)

    @publication.increment!(:views)
    session[:viewed_publications] ||= []
    session[:viewed_publications] << @publication.id
  end
end
