# frozen_string_literal: true

module Scanlators
  # Toolbar / Turbo-frame helpers for the public scanlator works catalog (search, sort, view).
  module WorksCatalogHelper
    WORKS_FRAME_ID = 'scanlator-works'
    DEFAULT_SORT = 'popular_desc'

    def self.normalize_sort(value)
      key = value.to_s
      FictionListQueryBuilder::SORTS.include?(key) ? key : DEFAULT_SORT
    end

    def scanlator_works_sort_key
      WorksCatalogHelper.normalize_sort(params[:sort])
    end

    def scanlator_works_path_with(scanlator, overrides = {})
      query = request.query_parameters.except('page')
      overrides.each { |key, value| query = apply_scanlator_works_param(query, key, value) }
      scanlator_path(scanlator, query)
    end

    def scanlator_works_pagy_custom_params
      {}.tap do |extra|
        query = params[:q].to_s.strip
        extra[:q] = query if query.present?
        extra[:view] = 'list' if params[:view] == 'list'
        sort = scanlator_works_sort_key
        extra[:sort] = sort unless sort == DEFAULT_SORT
      end
    end

    def scanlator_extra_link_label(url)
      host = URI.parse(url.to_s).host.presence
      host.present? ? host.delete_prefix('www.') : 'Зовнішнє посилання'
    rescue URI::InvalidURIError
      'Зовнішнє посилання'
    end

    private

    def apply_scanlator_works_param(query, key, value)
      string_key = key.to_s
      drop = value.nil? || value == false || value == '' ||
             (string_key == 'sort' && value.to_s == DEFAULT_SORT)
      drop ? query.except(string_key) : query.merge(string_key => value)
    end
  end
end
