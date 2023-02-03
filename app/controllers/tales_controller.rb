class TalesController < ApplicationController
  before_action :set_tale

  def show
  end

  private

  def set_tale
    @tale = Tale.find(params[:id])
  end
end