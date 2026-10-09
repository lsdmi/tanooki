# frozen_string_literal: true

module Api
  module Mcp
    module Tools
      # Creates one draft unless status is published. A repeated idempotency key returns the first chapter.
      class CreateChapter < MCP::Tool
        extend Hints

        tool_name 'create_chapter'
        title 'Create chapter'
        description 'Creates one chapter. status defaults to draft. Call list_chapters first so the number is free. ' \
                    'Publishing needs chapters:publish and status published. Then show edit_url. Needs chapters:write.'
        input_schema(
          properties: {
            fiction: { type: 'string', description: 'Fiction id or slug' },
            number: { type: 'number', description: 'Chapter number' },
            title: { type: 'string', description: 'Subtitle only. The site adds «Розділ N»' },
            content: { type: 'string', description: 'Markdown' },
            volume_number: { type: 'number' },
            content_format: { type: 'string', description: 'markdown (default) or html' },
            scanlator_ids: {
              type: 'array', items: { type: 'integer' },
              description: 'Caller’s teams. Default: teams already on this fiction'
            },
            status: { type: 'string', description: 'draft (default) or published' },
            published_at: { type: 'string', description: 'ISO 8601 schedule, in the future' },
            idempotency_key: { type: 'string', description: 'Same key for 24 hours returns the first chapter' }
          },
          required: %w[fiction number content]
        )
        writes

        def self.call(fiction:, number:, content:, server_context:, **options)
          Result.capture { create(fiction, number, content, Actor.from(server_context), options) }
        end

        def self.create(fiction, number, content, actor, options)
          actor.permit!('chapters:write')
          replay = Idempotency.read(actor.user, options[:idempotency_key])
          return replay.body if replay

          stored = write(fiction, number, content, actor, options)
          Idempotency.write(actor.user, options[:idempotency_key], status: 201, body: stored)
          stored
        end

        def self.write(fiction, number, content, actor, options)
          outcome = Chapters::Create.call(
            user: actor.user, token: actor.token, fiction_id: fiction,
            params: fields(number, content, options), via: 'mcp'
          )
          Chapters::Serialize.full(outcome.chapter, changes: outcome.changes, diff: { summary: 'created' })
        end

        def self.fields(number, content, options)
          params = { number:, title: options.fetch(:title, ''), content:, status: options.fetch(:status, 'draft') }
          %i[volume_number content_format scanlator_ids published_at].each do |key|
            params[key] = options[key] if options.key?(key)
          end
          params
        end
      end
    end
  end
end
