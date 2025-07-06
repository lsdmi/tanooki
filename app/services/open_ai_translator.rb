# frozen_string_literal: true

# Responsible for translating content using OpenAI
class OpenAiTranslator
  include ContentTranslatorInterface
  def translate(article_text, title, tags)
    prompt = translation_prompt(article_text, title, tags)
    response = call_openai_api(prompt)
    return nil if response.blank?

    parse_translation_response(response)
  rescue StandardError => e
    Rails.logger.error("Translation failed: #{e.message}")
    nil
  end

  private

  def call_openai_api(prompt)
    client = OpenAI::Client.new(
      access_token: ENV.fetch('OPENAI_API_KEY'),
      log_errors: true
    )

    response = client.chat(parameters: api_parameters(prompt))
    response.dig('choices', 0, 'message', 'content')
  end

  def api_parameters(prompt)
    {
      model: BlogScraperConfig.openai_model,
      messages: [
        { role: 'system', content: BlogScraperConfig.openai_system_prompt },
        { role: 'user', content: prompt }
      ],
      temperature: BlogScraperConfig.openai_temperature
    }
  end

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
