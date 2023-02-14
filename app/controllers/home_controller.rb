# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @highlight = Tale.highlight || Tale.last
    @top4 = Tale.all.order(created_at: :desc).excluding(@highlight).first(4)
    @pagy, @tales = pagy_countless(Tale.all.order(created_at: :desc).excluding(@highlight, @top4), items: 9)

    render 'scrollable_list' if params[:page]
  end
end
