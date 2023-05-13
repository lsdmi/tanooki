# frozen_string_literal: true

class FictionsController < ApplicationController
  before_action :set_fiction, :track_visit
  before_action :load_advertisement, only: :show

  def show
    @comments = @fiction.comments.parents.order(created_at: :desc)
    @comment = Comment.new
  end

  private

  def set_fiction
    @fiction = @commentable = Rails.cache.fetch("fiction_#{params[:id]}", expires_in: 1.hour) do
      Fiction.find(params[:id])
    end
  end
end
