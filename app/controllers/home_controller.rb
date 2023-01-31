class HomeController < ApplicationController
  def index
    @highlight = Tale.highlight
    @pagy, @tales = pagy_countless(Tale.news.order(created_at: :desc), items: 9)

    render "scrollable_list" if params[:page]
  end
end
