# frozen_string_literal: true

module Ui
  # Search index filter row: selected tab uses filter variant, others use keyword; counts match section pagy totals.
  class SearchFilterTabsComponent < ViewComponent::Base
    include Rails.application.routes.url_helpers

    Tab = Data.define(:label, :key, :count, :url, :selected)

    TABS = [
      { key: 'all', label: 'Усе' },
      { key: 'video', label: 'Відео' },
      { key: 'blog', label: 'Новини' },
      { key: 'fiction', label: 'Ранобе' }
    ].freeze

    def initialize(current_filter:, search:, pagy_fictions:, pagy_results:, pagy_videos:)
      super()
      @current_filter = current_filter
      @search = search
      @pagy_fictions = pagy_fictions
      @pagy_results = pagy_results
      @pagy_videos = pagy_videos
    end

    def tabs
      TABS.map do |tab|
        Tab.new(
          label: tab[:label],
          key: tab[:key],
          count: count_for(tab[:key]),
          url: filter_url(tab[:key]),
          selected: selected?(tab[:key])
        )
      end
    end

    private

    attr_reader :current_filter, :search, :pagy_fictions, :pagy_results, :pagy_videos

    def selected?(key)
      active_filter == key
    end

    def active_filter
      key = current_filter.to_s
      return 'all' if key.blank? || key == 'all'
      return key if %w[video blog fiction].include?(key)

      'all'
    end

    def count_for(key)
      case key
      when 'all' then fiction_count + results_count + videos_count
      when 'video' then videos_count
      when 'blog' then results_count
      when 'fiction' then fiction_count
      else 0
      end
    end

    def fiction_count
      pagy_fictions&.count.to_i
    end

    def results_count
      pagy_results&.count.to_i
    end

    def videos_count
      pagy_videos&.count.to_i
    end

    def filter_url(key)
      query = {}
      query[:search] = Array(search) if search.present?
      query[:filter] = key unless key == 'all'
      search_index_path(query)
    end
  end
end
