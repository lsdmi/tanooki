# frozen_string_literal: true

class TalesController < ApplicationController
  before_action :set_tale

  def show
    @more_tales = Tale.order(created_at: :desc).excluding(@publication).first(6)
    @comments = @publication.comments.parents.order(created_at: :desc)
    @comment = Comment.new
    @advertisement = Advertisement.enabled.sample
  end

  private

  def set_tale
    @publication = Tale.find(params[:id])
  end
end
