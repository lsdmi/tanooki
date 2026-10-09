# frozen_string_literal: true

module Api
  module Mcp
    # House style the assistant should read before it writes a chapter.
    class FormattingGuide < MCP::Resource
      GUIDE = <<~TEXT
        Заголовок «Розділ N» сайт додає сам. У title надсилайте лише підзаголовок.

        Текст — Markdown.
        Абзаци розділяє порожній рядок. Один перенос лишається в тому самому абзаці.
        **жирний**, *курсив*, ~~закреслений~~. Діалог починайте з тире «—». Лапки — «ялинки».
        Нова сцена — рядок --- або ***.
        Примітка чіпляється до слова перед маркером: слово[^1]
        [^1]: текст примітки
        Картинку спочатку отримайте через upload_image_from_url, потім вставте ![опис](url).
        За замовчуванням розділ — чернетка. Перед create_chapter викличте list_chapters.
        Дрібну правку робіть через edit_paragraphs, не замінюйте весь текст.
        Після запису покажіть людині edit_url і що змінилось.
      TEXT

      uri 'baka://formatting-guide'
      resource_name 'formatting-guide'
      title 'Як оформлювати розділ'
      description 'Markdown, примітки, діалоги й те, що сайт очікує від помічника.'
      mime_type 'text/markdown'

      def self.contents
        MCP::Resource::TextContents.new(uri: uri_value, mime_type: 'text/markdown', text: GUIDE)
      end
    end
  end
end
