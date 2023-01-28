class HomeController < ApplicationController
  def index
    @highlight = Tale.highlight
    @tales = Tale.news # + Tale.news + Tale.news + Tale.news
  end
end
