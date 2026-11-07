# frozen_string_literal: true

module Meta
  # Contest show SEO copy for <title> and meta description.
  class ContestSeo
    ARCHIVE_SUFFIX = 'Архів конкурсу | Бака'
    LIVE_SUFFIX = 'Конкурс ранобе | Бака'
    ARCHIVE_TAIL = 'Підсумки та роботи на Баці.'
    LIVE_TAIL = 'Умови, роботи й призи на Баці.'
    MAX_DESCRIPTION_LENGTH = 160
    SENTENCE_BOUNDARY = /(?<=[.?!])\s+/

    def initialize(contest)
      @contest = contest
    end

    def page_title
      titled(contest.title)
    end

    def meta_description
      parts = []
      if (body = blurb).present?
        body = "#{body}." unless body.match?(/[.!?…]\z/)
        parts << body
      end
      parts << (archive? ? ARCHIVE_TAIL : LIVE_TAIL)
      parts.join(' ').squish.truncate(MAX_DESCRIPTION_LENGTH, separator: /\s/, omission: '…')
    end

    private

    attr_reader :contest

    def titled(head)
      "#{head} | #{archive? ? ARCHIVE_SUFFIX : LIVE_SUFFIX}"
    end

    def archive?
      Contests::Phase.new(contest).call == :results
    end

    def blurb
      contest.tagline.to_s.strip.presence || first_sentence(description_text)
    end

    def description_text
      contest.description.to_plain_text.to_s
    end

    def first_sentence(text)
      cleaned = text.to_s.gsub(/\r\n?/, "\n").strip
      return if cleaned.blank?

      cleaned.split(/\n+/).flat_map { |paragraph| paragraph.split(SENTENCE_BOUNDARY) }.map(&:strip).find(&:present?)
    end
  end
end
