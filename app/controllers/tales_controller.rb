# frozen_string_literal: true

class TalesController < ApplicationController
  before_action :set_tale

  def show
    @more_tales = Tale.all.order(created_at: :desc).excluding(@tale).first(4)
    @comments = @publication.comments.parents.order(created_at: :desc)
    @comment = Comment.new
  end

  private

  def set_tale
    @publication = Tale.find(params[:id])
  end
end
