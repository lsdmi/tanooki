# frozen_string_literal: true

module Fictions
  # Tag part of the catalog filter: the slugs in the URL, the drawer options, and the chips above the results.
  module CatalogTagFilterHelper
    def catalog_tag_slugs
      Array(Fictions::ListFilters.permit_for_pagy(params)[:tags])
    end

    def catalog_tags_selected?
      catalog_tag_slugs.any?
    end

    def catalog_selected_tags
      @catalog_selected_tags ||= FictionTags::CatalogFacet.selected(catalog_tag_slugs, explicit: catalog_explicit_tags?)
    end

    def catalog_tag_options
      FictionTags::CatalogFacet.options(explicit: catalog_explicit_tags?)
    end

    # The reader selected a 18+ tag but has 18+ off: the tag is hidden, so say why instead of a bare empty list.
    def catalog_adult_tag_hidden?
      !catalog_explicit_tags? && FictionTags::CatalogFacet.selected(catalog_tag_slugs, explicit: true).any?
    end

    def catalog_tag_path_without(slug)
      catalog_path_with(tags: (catalog_tag_slugs - [slug]).presence)
    end
  end
end
