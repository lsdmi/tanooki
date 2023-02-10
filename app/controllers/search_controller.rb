class SearchController < ApplicationController
  def index
    redirect_to root_path unless params[:search]

    @results = Tale.search params[:search], fields: ["title^5", "description"], order: { _score: :desc }
  end
end
