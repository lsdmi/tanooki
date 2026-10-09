# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # Fetches one image and returns the storage URL to put in Markdown.
      class UploadImageFromUrl < MCP::Tool
        extend Hints

        tool_name 'upload_image_from_url'
        title 'Upload image from URL'
        description 'Downloads one https image and returns a URL for Markdown ![alt](url). ' \
                    'Private and local addresses are refused. Needs images:write.'
        input_schema(
          properties: { url: { type: 'string', description: 'Public https image URL' } },
          required: ['url']
        )
        writes

        def self.call(url:, server_context:)
          Result.capture { store(url, Actor.from(server_context)) }
        end

        def self.store(url, actor)
          actor.permit!('images:write')
          download = UrlFetch.to_tempfile(url)
          image = ::Chapters::ImageProcessor.call(download.path)
          raise Error.new('unsupported_image', :unprocessable_entity) if image.nil?

          { url: ::Chapters::Images.url_for(::Chapters::Images.store!(image)) }
        ensure
          download&.close!
        end
      end
    end
  end
end
