# frozen_string_literal: true

class ChaptersCalendarController < ApplicationController
  # Bump when calendar payload shape changes (e.g. presenter hash keys).
  CALENDAR_CACHE_VERSION = 2

  before_action :pokemon_appearance, only: [:index]

  def index
    @fictions = calendar_updates
    @subscriptions_filter_active = subscriptions_filter?

    respond_to do |format|
      format.html
      format.turbo_stream { render turbo_stream: refresh_list }
    end
  end

  private

  def refresh_list
    turbo_stream.update(
      'chapters_calendar_updates',
      partial: 'chapters_calendar/updates_frame',
      locals: { fictions: @fictions }
    )
  end

  def subscriptions_filter?
    user_signed_in? && ActiveModel::Type::Boolean.new.cast(params[:subscriptions])
  end

  def calendar_updates
    if subscriptions_filter?
      Rails.cache.fetch(
        ['cached_fictions', 'subscriptions', current_user.id, CALENDAR_CACHE_VERSION],
        expires_in: 15.minutes
      ) do
        FictionUpdatesPresenter.new(user: current_user, subscriptions_only: true).last_three_days_updates
      end
    else
      cached_all_fictions
    end
  end

  def cached_all_fictions
    Rails.cache.fetch(['cached_fictions', CALENDAR_CACHE_VERSION], expires_in: 15.minutes) do
      FictionUpdatesPresenter.new.last_three_days_updates
    end
  end
end
