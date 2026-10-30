# frozen_string_literal: true

module Fictions
  # Pagy custom params and catalog sort helpers for fiction-list Turbo frames.
  module ListPaginationHelper
    # After two desktop gallery rows (6×2) / mid-page in the 24-item list view.
    CATALOG_MID_AD_AFTER = 12

    CATALOG_SORT_BUTTON_LABELS = {
      'title_asc' => 'А-Я',
      'title_desc' => 'Я-А',
      'updated_desc' => 'Нові оновлення',
      'updated_asc' => 'Старі оновлення',
      'popular_desc' => 'Популярні',
      'popular_asc' => 'Менш популярні',
      'rating_desc' => 'Найкращі',
      'rating_asc' => 'Найгірші'
    }.freeze

    def fiction_list_pagy_custom_params
      Fictions::ListFilters.permit_for_pagy(params).tap do |extra|
        merge_catalog_pagy_extras!(extra)
      end
    end

    def catalog_sort_key
      FictionListQueryBuilder.normalize_sort(params[:sort])
    end

    def catalog_sort_button_label(key = catalog_sort_key)
      CATALOG_SORT_BUTTON_LABELS.fetch(key, CATALOG_SORT_BUTTON_LABELS.fetch(FictionListQueryBuilder::DEFAULT_SORT))
    end

    def catalog_sort_option_label(key)
      I18n.t("fiction_lists.sort.#{key}")
    end

    def catalog_sort_options
      FictionListQueryBuilder::SORTS.map { |key| [catalog_sort_option_label(key), key] }
    end

    def catalog_path_with(overrides = {})
      query = request.query_parameters.except('page')
      overrides.each { |key, value| query = apply_catalog_param(query, key, value) }
      alphabetical_fictions_path(query)
    end

    def catalog_filter_hidden_fields
      Fictions::ListFilters.permit_for_pagy(params)
    end

    def catalog_active_filter_count
      catalog_filter_hidden_fields.size
    end

    def catalog_mid_ad?(index:, total:)
      return false if total.zero?

      insert_after = [CATALOG_MID_AD_AFTER, total].min
      index + 1 == insert_after
    end

    private

    def merge_catalog_pagy_extras!(extra)
      query = params[:q].to_s.strip
      extra[:q] = query if query.present?
      extra[:view] = 'list' if params[:view] == 'list'
      sort = FictionListQueryBuilder.normalize_sort(params[:sort])
      extra[:sort] = sort unless sort == FictionListQueryBuilder::DEFAULT_SORT
    end

    def apply_catalog_param(query, key, value)
      string_key = key.to_s
      drop = value.nil? || value == false || value == '' ||
             (string_key == 'sort' && value.to_s == FictionListQueryBuilder::DEFAULT_SORT)
      drop ? query.except(string_key) : query.merge(string_key => value)
    end
  end
end
