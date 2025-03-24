# frozen_string_literal: true

class ChaptersCalendarController < ApplicationController
  def index
    @fictions = FictionUpdatesPresenter.new.last_three_days_updates
  end
end
