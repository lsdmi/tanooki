# frozen_string_literal: true

module Meta
  # View entry point for page meta descriptions; delegates to Meta::PageDescription.
  module DescriptionHelper
    def meta_description
      Meta::PageDescription.new(**page_description_context).resolve
    end

    private

    def page_description_context
      page_description_assigns.merge(page_description_request_context)
    end

    def page_description_assigns
      %i[publication fiction chapter youtube_video bookshelf scanlator genre]
        .index_with { |name| meta_assign(name) }
    end

    def page_description_request_context
      {
        request_path: request.path,
        controller_name: controller_name,
        action_name: action_name,
        genre_show_page: genre_show_page?
      }
    end
  end
end
