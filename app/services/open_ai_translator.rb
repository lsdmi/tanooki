# frozen_string_literal: true

# Responsible for translating content using OpenAI
class OpenAiTranslator
  include ContentTranslatorInterface
  def translate(article_text, title, tags)
    client = OpenAI::Client.new(
      access_token: ENV.fetch('OPENAI_API_KEY'),
      log_errors: true
    )

    prompt = translation_prompt(article_text, title, tags)
    response = client.chat(
      parameters: {
        model: BlogScraperConfig.openai_model,
        messages: [
          { role: 'system', content: BlogScraperConfig.openai_system_prompt },
          { role: 'user', content: prompt }
        ],
        temperature: BlogScraperConfig.openai_temperature
      }
    )

    content = response.dig('choices', 0, 'message', 'content')
    return nil if content.blank?

    parse_translation_response(content)
  rescue StandardError => e
    Rails.logger.error("Translation failed: #{e.message}")
    nil
  end

  private

  def translation_prompt(article_text, title, tags)
    <<~PROMPT
      Переклади статтю українською мовою та оформи її у простому HTML.
      Вимоги:
      - Поверни лише внутрішній вміст <body> (без тегів <html>, <head>, <body>), без класів, стилів чи будь-яких атрибутів - тільки чисті HTML-теги.
      - Перший рядок - це заголовок статті у вигляді <h1>.
      - Дати в тексті потрібно виділити жирним шрифтом за допомогою <b>.
      - Якщо в статті є списки, не використовуй <ul>, <ol> чи <li>. Замість цього створи марковані списки вручну, використовуючи символ •.
      - Використовуй базові HTML-елементи для структурування тексту (наприклад, <b>, <i>, <p>), але нічого зайвого.

      Ось список можливих тегів для статті у форматі [{id: ..., name: "..."}]:
      #{tags.to_json}

      Вибери всі теги, які найкраще відповідають змісту цієї статті. Обов'язково вибери хоча б один тег.
      Поверни масив id вибраних тегів у форматі JSON у кінці відповіді, наприклад:
      [1, 3, 7]

      НАЗВА (підсумуй українською, має бути короткою та влучною): #{title}
      СТАТТЯ (переклади українською):
      #{article_text}
    PROMPT
  end

  def parse_translation_response(content)
    tag_ids = content.scan(/\[(?:\d+,?\s*)+\]/).last
    tag_ids = tag_ids ? JSON.parse(tag_ids) : []
    summary_html = content.sub(/\[(?:\d+,?\s*)+\]\s*\z/, '').strip

    TranslatedContent.new(
      html: summary_html,
      tag_ids: tag_ids
    )
  end
end
