# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @highlight = Publication.highlight || Tale.last
    @top_four = Tale.order(created_at: :desc).excluding(@highlight).first(4)

    remaining_publications = Publication.approved.order(created_at: :desc).excluding(@highlight, @top_four)
    @pagy, @publications = pagy_countless(remaining_publications, items: 5)

    @advertisement = Advertisement.enabled.sample

    render 'scrollable_list' if params[:page]
  end
end
