# frozen_string_literal: true

# Calendar of recent chapter releases, optionally filtered to subscribed fictions.
class ChaptersCalendarController < ApplicationController
  # Bump when calendar payload shape changes (e.g. presenter hash keys).
  CALENDAR_CACHE_VERSION = 4

  before_action :pokemon_appearance, only: [:index]

  def index
    @fictions = calendar_updates
    @subscriptions_filter_active = subscriptions_filter?

    respond_to do |format|
      format.html
      format.turbo_stream { render turbo_stream: turbo_stream_list_refresh(refresh_list) }
    end
  end

  private

  def refresh_list
    turbo_stream.update(
      'chapters_calendar_updates',
      partial: 'chapters_calendar/updates_frame',
      locals: {
        fictions: @fictions,
        subscriptions_filter_active: @subscriptions_filter_active,
        content_filter_hidden: @content_filter_hidden
      }
    )
  end

  def subscriptions_filter?
    user_signed_in? && ActiveModel::Type::Boolean.new.cast(params[:subscriptions])
  end

  def calendar_updates
    if subscriptions_filter?
      @content_filter_hidden = 0
      cached_subscription_updates
    else
      filter_calendar_days(cached_all_fictions)
    end
  end

  def cached_subscription_updates
    Rails.cache.fetch(
      ['cached_fictions', 'subscriptions', current_user.id, CALENDAR_CACHE_VERSION],
      expires_in: 15.minutes
    ) do
      FictionUpdatesPresenter.new(user: current_user, subscriptions_only: true).last_three_days_updates
    end
  end

  def filter_calendar_days(days)
    @content_filter_hidden = 0
    return days unless current_content_filter.active?

    days.map { |day| day.merge(updates: visible_calendar_updates(day)) }
  end

  def visible_calendar_updates(day)
    updates = day[:updates].select { |update| calendar_update_visible?(update) }
    @content_filter_hidden += day[:updates].size - updates.size
    updates
  end

  def calendar_update_visible?(update)
    return false if rating_hidden?(update[:content_rating])

    !current_content_filter.rejects_genre_ids?(update[:genre_ids])
  end

  def rating_hidden?(rating)
    max_rating = current_content_filter.max_rating
    !max_rating.nil? && !rating.nil? && rating > max_rating
  end

  def cached_all_fictions
    Rails.cache.fetch(['cached_fictions', CALENDAR_CACHE_VERSION], expires_in: 15.minutes) do
      FictionUpdatesPresenter.new.last_three_days_updates
    end
  end
end
