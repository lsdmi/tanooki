# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    redirect_to root_path unless params[:search]

    @results = Publication.search params[:search], fields: ['title^5', 'description'], order: { _score: :desc }
  end
end
