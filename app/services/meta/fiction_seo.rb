# frozen_string_literal: true

module Meta
  # Shared fiction show SEO copy for <title>, meta description, and Book JSON-LD.
  class FictionSeo
    TITLE_SUFFIX = 'Ранобе українською | Бака'
    READ_TAIL = 'Читати українською на Баці'
    MAX_TITLE_LENGTH = 70
    MAX_DESCRIPTION_LENGTH = 160
    MAX_SCANLATORS_NAMED = 2
    # Prefer \p{L} over \w — MRI \w is ASCII-only here and breaks Cyrillic stems.
    ANNOUNCEMENT_LINE = /\A(?:
      ЗУПИНКА\s+ПЕРЕКЛАДУ|
      STOP(?:PED)?\s+TRANSLATION|
      ПЕРЕКЛАД\s+ЗУПИНЕН|
      Детальн\p{L}*\s+інформац|
      Telegram\s+канал|
      Телеграм(?:\s+канал)?
    )/ix
    SENTENCE_BOUNDARY = /(?<=[.?!])\s+/

    def initialize(fiction)
      @fiction = fiction
    end

    def page_title
      with_english = titled("#{fiction.title} (#{english_title})") if english_title.present?
      return with_english if with_english && with_english.length <= MAX_TITLE_LENGTH

      titled(fiction.title)
    end

    def meta_description
      parts = []
      parts << alternate_names_phrase if alternate_names.any?
      parts << blurb if blurb.present?
      parts << "#{READ_TAIL}#{scanlator_or_author_phrase}."
      parts.join(' ').squish.truncate(MAX_DESCRIPTION_LENGTH, separator: /\s/, omission: '…')
    end

    def json_ld_description
      meta_description
    end

    def alternate_names
      [english_title, alternative_title].compact
    end

    private

    attr_reader :fiction

    def titled(head)
      "#{head} | #{TITLE_SUFFIX}"
    end

    def english_title
      fiction.english_title.presence
    end

    def alternative_title
      fiction.alternative_title.presence
    end

    def alternate_names_phrase
      "#{alternate_names.join(' / ')}."
    end

    def blurb
      short = fiction.short_description.to_s.strip.presence
      return short if short

      first_meaningful_sentence(fiction.description.to_s)
    end

    def first_meaningful_sentence(text)
      cleaned = text.to_s.gsub(/\r\n?/, "\n").strip
      return if cleaned.blank?

      cleaned.split(/\n+/).flat_map { |paragraph| paragraph.split(SENTENCE_BOUNDARY) }.each do |sentence|
        sentence = sentence.strip
        next if sentence.blank?
        next if sentence.match?(ANNOUNCEMENT_LINE)

        return sentence
      end

      nil
    end

    def scanlator_or_author_phrase
      titles = fiction.scanlators.filter_map { |scanlator| scanlator.title.presence }
      return author_phrase if titles.empty?

      named = titles.first(MAX_SCANLATORS_NAMED)
      list = named.map { |title| "«#{title}»" }.join(' і ')
      suffix = titles.size > MAX_SCANLATORS_NAMED ? ' та ін.' : ''
      label = named.size == 1 ? 'команди' : 'команд'
      " у перекладі #{label} #{list}#{suffix}"
    end

    def author_phrase
      return '' if fiction.author.blank?

      " · автор «#{fiction.author}»"
    end
  end
end
