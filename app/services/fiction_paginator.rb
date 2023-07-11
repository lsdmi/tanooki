# frozen_string_literal: true

class FictionPaginator
  include LibraryHelper
  include Pagy::Backend

  def initialize(pagy, fictions, params)
    @fictions = fictions
    @paginators = {}
    @pagy = pagy
    @params = params
  end

  def call
    @fictions.each do |fiction|
      instance_variable_set(paginated_chapters_name(fiction), paginated_chapters(fiction))
      instance_variable_set(fictions_name(fiction), fiction)
      @paginators[fiction.slug] = {
        paginated_chapters: instance_variable_get(paginated_chapters_name(fiction)),
        fictions: instance_variable_get(fictions_name(fiction))
      }
    end
  end

  def initiate
    @paginators
  end

  def paginated_chapters_name(fiction)
    "@paginated_chapters_#{fiction.slug.gsub('-', '_')}"
  end

  def fictions_name(fiction)
    "@fictions_#{fiction.slug.gsub('-', '_')}"
  end

  def paginated_chapters(fiction)
    pagy(
      ordered_chapters_desc(fiction),
      page: @params["chapter_page_#{fiction.slug}"] || 1,
      items: 8,
      page_param: "chapter_page_#{fiction.slug}"
    )
  end
end
