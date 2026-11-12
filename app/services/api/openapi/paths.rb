# frozen_string_literal: true

module Api
  module Openapi
    CHAPTER_PATCH = 'Можна передати title, content, volume_number, status, published_at, ' \
                    'scanlator_ids, content_format (markdown за замовчуванням, або html); ' \
                    'для заміни тексту потрібна version.'
    PARAGRAPH_EDITS = 'Тіло: version і edits[{n, old, new}]. old — Markdown з paragraphs. ' \
                      'Неторкані абзаци лишають HTML. Текстова правка зі тією ж розміткою ' \
                      'переписує лише текст усередині HTML (стилі й примітки лишаються); ' \
                      'old == new нічого не змінює. Нова розмітка або розбиття абзацу — ' \
                      'перезбірка блоку з Markdown.'

    # Path map for the team OpenAPI document.
    module Paths
      MAP = {
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
            summary: 'Каталог розділів без тексту',
            description: 'Метадані розділів, які бачить команда ключа: id, number, title, status, ' \
                         'volume_number, team_ids, published_at, created_via. Без html, paragraphs і version. ' \
                         'Чужі команди відсутні. Для великих творів використовуйте from/to.',
            parameters: [
              { name: 'fiction_id', in: 'path', required: true, schema: { type: 'string' } },
              *RANGE_PARAMS
            ],
            responses: { '200': { description: 'Список без тексту й version' } }
          },
          post: {
            summary: 'Новий розділ',
            description: 'Тіло JSON: number, title, content; опційно volume_number (том), ' \
                         'status, published_at, scanlator_ids, content_format.',
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
          get: {
            summary: 'Кілька розділів з текстом',
            description: 'До 5 розділів у діапазоні номерів, з version. Обрізається також за сумарним ' \
                         'розміром HTML (~200 КБ). Не замінює каталог: спочатку list, потім batch пачками.',
            parameters: [
              { name: 'fiction_id', in: 'path', required: true, schema: { type: 'string' } },
              *RANGE_PARAMS, BODY_PARAM
            ],
            responses: { '200': { description: 'До 5 розділів' } }
          }
        },
        '/fictions/{fiction_id}/chapters/by_number/{number}' => {
          get: {
            summary: 'Розділ за номером',
            description: 'Повний розділ з version. Якщо кілька команд мають той самий номер — 409 ambiguous.',
            parameters: [
              { name: 'fiction_id', in: 'path', required: true, schema: { type: 'string' } },
              { name: 'number', in: 'path', required: true, schema: { type: 'number' } },
              { name: 'volume', in: 'query', description: 'Том, коли номер не унікальний', schema: { type: 'number' } },
              { name: 'team_id', in: 'query', schema: { type: 'integer' } },
              BODY_PARAM
            ],
            responses: { '200': { description: 'Розділ' }, '409': { description: 'Кілька збігів' } }
          }
        },
        '/chapters/{id}' => {
          get: {
            summary: 'Один розділ',
            description: 'Повний розділ з version, html і/або paragraphs. version беріть звідси перед записом.',
            parameters: [
              { name: 'id', in: 'path', required: true, schema: { type: 'integer' } },
              BODY_PARAM
            ],
            responses: { '200': { description: 'Розділ з абзацами' } }
          },
          patch: {
            summary: 'Часткова зміна',
            description: CHAPTER_PATCH,
            responses: { '200': { description: 'Оновлено' }, '409': { description: 'version застаріла' } }
          }
        },
        '/chapters/{id}/paragraph_edits' => {
          post: { summary: 'Правка абзаців', description: PARAGRAPH_EDITS,
                  responses: { '200': { description: 'Оновлено' }, '409': { description: 'version застаріла' } } }
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
          post: { summary: 'Зображення файлом або за URL',
                  responses: { '201': { description: 'Адреса для Markdown' } } }
        }
      }.freeze
    end
  end
end
