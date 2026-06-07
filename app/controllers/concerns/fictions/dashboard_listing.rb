# frozen_string_literal: true

module Fictions
  # Paginated fiction list for dashboard destroy turbo responses.
  module DashboardListing
    extend ActiveSupport::Concern

    private

    def ordered_fiction_list
      current_user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
    end

    def paginate_fictions
      pagy(
        ordered_fiction_list,
        limit: 6,
        request_path: readings_path,
        page: fiction_page || 1
      )
    end

    def fiction_page
      (params[:page].to_i - 1) if Fiction.count <= (params[:page].to_i * 8) - 8
    end
  end
end
