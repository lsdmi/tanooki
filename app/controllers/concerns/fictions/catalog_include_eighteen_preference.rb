# frozen_string_literal: true

module Fictions
  # Remembers alphabetical «Показувати 18+» for this browser session only.
  module CatalogIncludeEighteenPreference
    extend ActiveSupport::Concern

    SESSION_KEY = :catalog_include_eighteen

    included do
      helper_method :catalog_include_eighteen?
    end

    private

    def catalog_include_eighteen?
      @catalog_include_eighteen
    end

    def resolve_catalog_include_eighteen
      @catalog_include_eighteen =
        if params[:filters_applied].present? || ListFilters.include_eighteen_param_specified?(params)
          ListFilters.include_eighteen?(params).tap { |value| persist_catalog_include_eighteen(value) }
        else
          session[SESSION_KEY].present?
        end
    end

    def persist_catalog_include_eighteen(value)
      if value
        session[SESSION_KEY] = true
      else
        session.delete(SESSION_KEY)
      end
    end
  end
end
