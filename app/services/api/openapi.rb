# frozen_string_literal: true

module Api
  # OpenAPI 3.1 description of the team API. The public Hikka catalog is a different controller.
  module Openapi
    BODY_PARAM = {
      name: 'body', in: 'query',
      description: 'Що повернути в тілі розділу: all (html + paragraphs, за замовчуванням), ' \
                   'html (лише HTML), paragraphs (лише нумеровані абзаци Markdown). ' \
                   'Для порівняння/синку тексту беріть body=html.',
      schema: { type: 'string', enum: %w[all html paragraphs], default: 'all' }
    }.freeze

    RANGE_PARAMS = [
      { name: 'from', in: 'query', description: 'Перший номер розділу (включно)', schema: { type: 'number' } },
      { name: 'to', in: 'query', description: 'Останній номер розділу (включно)', schema: { type: 'number' } },
      {
        name: 'team_id', in: 'query',
        description: 'Лише розділи цієї команди ключа', schema: { type: 'integer' }
      }
    ].freeze

    DOCUMENT = {
      openapi: '3.1.0',
      info: {
        title: 'Бака: API для команд',
        version: '1.1.0',
        description: <<~TEXT.squish
          Експериментальне API для розділів команд, у яких складається власник ключа.
          Ключ створюється в Студії, на вкладці команд. Секрет показується один раз.
          Читання: спочатку GET /fictions/{id}/chapters — лише метадані (без тексту й без version);
          текст беріть окремо через GET /chapters/{id}, by_number або batch (до 5 розділів).
          version є лише у відповідях з текстом; його треба передати в PATCH / paragraph_edits.
          Тяжкі твори з ілюстраціями: не тягніть увесь каталог з тілами; для порівняння тексту
          використовуйте body=html.
        TEXT
      },
      servers: [{ url: 'https://baka.in.ua/api/v1' }],
      security: [{ bearer: [] }],
      components: {
        securitySchemes: {
          bearer: { type: 'http', scheme: 'bearer', description: 'Ключ, що починається з baka_' }
        }
      },
      paths: Paths::MAP
    }.freeze
  end
end
