# frozen_string_literal: true

module Api
  # OpenAPI 3.1 description of the team API. The public Hikka catalog is a different controller.
  module Openapi
    DOCUMENT = {
      openapi: '3.1.0',
      info: {
        title: 'Бака: API для команд',
        version: '1.0.0',
        description: 'Експериментальне API для розділів команд, у яких складається власник ключа. ' \
                     'Ключ створюється в Студії, на вкладці команд. Секрет показується один раз.'
      },
      servers: [{ url: 'https://baka.in.ua/api/v1' }],
      security: [{ bearer: [] }],
      components: {
        securitySchemes: {
          bearer: { type: 'http', scheme: 'bearer', description: 'Ключ, що починається з baka_' }
        }
      },
      paths: {
        '/openapi' => { get: { security: [], summary: 'Цей опис', responses: { '200': { description: 'OpenAPI' } } } },
        '/me' => { get: { summary: 'Хто цей ключ', responses: { '200': { description: 'Користувач і команди' } } } },
        '/me/fictions' => {
          get: {
            summary: 'Твори команд ключа',
            parameters: [{ name: 'q', in: 'query', schema: { type: 'string' } }],
            responses: { '200': { description: 'Список творів' } }
          }
        },
        '/fictions/{fiction_id}/chapters' => {
          get: {
            summary: 'Розділи твору, які бачить команда',
            parameters: [{ name: 'fiction_id', in: 'path', required: true, schema: { type: 'string' } }],
            responses: { '200': { description: 'Список без тексту' } }
          },
          post: {
            summary: 'Новий розділ',
            parameters: [
              { name: 'fiction_id', in: 'path', required: true, schema: { type: 'string' } },
              { name: 'Idempotency-Key', in: 'header', schema: { type: 'string' } }
            ],
            responses: {
              '201': { description: 'Створено' },
              '409': { description: 'Такий номер уже є' }
            }
          }
        },
        '/fictions/{fiction_id}/chapters/batch' => {
          get: { summary: 'Кілька розділів з текстом', responses: { '200': { description: 'До 5 розділів' } } }
        },
        '/fictions/{fiction_id}/chapters/by_number/{number}' => {
          get: {
            summary: 'Розділ за номером',
            responses: { '200': { description: 'Розділ' }, '409': { description: 'Кілька збігів' } }
          }
        },
        '/chapters/{id}' => {
          get: { summary: 'Один розділ', responses: { '200': { description: 'Розділ з абзацами' } } },
          patch: {
            summary: 'Часткова зміна',
            responses: { '200': { description: 'Оновлено' }, '409': { description: 'version застаріла' } }
          }
        },
        '/chapters/{id}/paragraph_edits' => {
          post: { summary: 'Правка абзаців', responses: { '200': { description: 'Оновлено' } } }
        },
        '/chapters/{id}/revisions' => {
          get: { summary: 'Історія правок API', responses: { '200': { description: 'Список' } } }
        },
        '/chapters/{id}/revisions/{revision_id}/diff' => {
          get: { summary: 'Різниця з поточною версією', responses: { '200': { description: 'Абзаци' } } }
        },
        '/chapters/{id}/revisions/{revision_id}/revert' => {
          post: { summary: 'Повернути цю версію', responses: { '200': { description: 'Відновлено' } } }
        },
        '/chapter_images' => {
          post: {
            summary: 'Зображення файлом або за URL',
            responses: { '201': { description: 'Адреса для Markdown' } }
          }
        }
      }
    }.freeze
  end
end
