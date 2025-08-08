# frozen_string_literal: true

class ChaptersCalendarController < ApplicationController
  before_action :pokemon_appearance, only: [:index]

  def index
    @fictions = cached_fictions
  end

  private

  def cached_fictions
    Rails.cache.fetch('cached_fictions', expires_in: 15.minutes) do
      FictionUpdatesPresenter.new.last_three_days_updates
    end
  end
end
