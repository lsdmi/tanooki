# frozen_string_literal: true

module Meta
  # View entry point for page titles; delegates to Meta::PageTitle.
  module TitleHelper
    def meta_title
      Meta::PageTitle.new(**page_title_context).resolve
    end

    private

    def page_title_context
      page_title_assigns.merge(page_title_request_context)
    end

    def page_title_assigns
      %i[publication fiction chapter youtube_video scanlator user bookshelf genre]
        .index_with { |name| meta_assign(name) }
    end

    def page_title_request_context
      {
        request_path: request.path,
        controller_name: controller_name,
        action_name: action_name,
        genre_show_page: genre_show_page?,
        search_index_page: request.path == search_index_path,
        search_terms: params[:search]
      }
    end
  end
end
