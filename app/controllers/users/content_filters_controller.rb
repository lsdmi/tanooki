# frozen_string_literal: true

module Users
  # Saves an account filter, or a guest «hide 18+» cookie. Guests cannot store genres.
  class ContentFiltersController < ApplicationController
    include Fictions::CatalogIncludeEighteenPreference

    GUEST_TOGGLE_IDS = %w[guest-content-filter-mobile guest-content-filter-desktop].freeze

    def update
      current_user ? update_account : update_guest
    end

    private

    def update_account
      result = ContentFilters::Replace.call(
        user: current_user,
        max_content_rating: rating_param,
        package_keys: filter_params[:package_keys]
      )
      streams = result.success? ? turbo_stream_notice(t('content_filters.saved')) : turbo_stream_alert(result.error)
      status = result.success? ? :ok : :unprocessable_content
      render turbo_stream: [*streams, replace_card(result.error)], status:
    end

    def update_guest
      write_guest_cookie
      @current_content_filter = nil
      @catalog_include_eighteen = session[Fictions::CatalogIncludeEighteenPreference::SESSION_KEY].present?
      render turbo_stream: [
        *turbo_stream_notice(t('content_filters.saved')),
        *replace_guest_toggles,
        *replace_catalog_eighteen_checkboxes
      ]
    end

    def write_guest_cookie
      if rating_param.to_s == '16'
        cookies.signed[ContentFilters::Resolver::COOKIE_KEY] = {
          value: ContentFilters::Resolver::GUEST_HIDE_EIGHTEEN,
          expires: 1.year.from_now,
          httponly: true,
          same_site: :lax
        }
      else
        cookies.delete(ContentFilters::Resolver::COOKIE_KEY)
      end
    end

    def filter_params
      params.permit(:max_content_rating, package_keys: [])
    end

    def rating_param
      rating = filter_params[:max_content_rating]
      rating.is_a?(Array) ? rating.last : rating
    end

    def replace_card(error)
      turbo_stream.replace('content-filter-card', partial: 'studio/tabs/content_filter', locals: { error: })
    end

    def replace_guest_toggles
      GUEST_TOGGLE_IDS.map do |dom_id|
        turbo_stream.replace(dom_id, partial: 'fiction_lists/guest_content_filter', locals: { dom_id: })
      end
    end

    def replace_catalog_eighteen_checkboxes
      GUEST_TOGGLE_IDS.map do |dom_id|
        turbo_stream.replace(
          "catalog-include-eighteen-#{dom_id}",
          partial: 'fiction_lists/include_eighteen',
          locals: { guest_toggle_id: dom_id }
        )
      end
    end
  end
end
