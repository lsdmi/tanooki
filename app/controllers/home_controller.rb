# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @highlight = Tale.highlight || Tale.last
    @pagy, @tales = pagy_countless(Tale.all.order(created_at: :desc).excluding(@highlight), items: 9)

    render 'scrollable_list' if params[:page]
  end
end
