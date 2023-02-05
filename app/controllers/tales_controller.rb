class TalesController < ApplicationController
  before_action :set_tale

  def show
    @more_tales = Tale.all.order(created_at: :desc).excluding(@tale).first(4)
    @comments = @tale.comments
  end

  private

  def set_tale
    @tale = Tale.find(params[:id])
  end
end