# frozen_string_literal: true

module Reading
  # Where the reader stopped inside a chapter, as reported by the reader page: the text of the first visible
  # block (quote), its data-rp-i index, how far through #user-content the viewport top is (percent), and the
  # digest that index belongs to (see Chapters::ReaderBlocks). Malformed parts are dropped; without a percent
  # there is no locator at all, since percent is the fallback every restore can use.
  class ResumeLocator
    QUOTE_LENGTH = 120
    MAX_BLOCK_INDEX = 100_000
    DIGEST_FORMAT = /\A\h{#{Chapters::ReaderBlocks::DIGEST_LENGTH}}\z/
    CLEARED = { resume_quote: nil, resume_block_index: nil, resume_percent: nil, resume_digest: nil }.freeze

    attr_reader :quote, :block_index, :percent, :digest

    def self.parse(raw)
      return unless raw.respond_to?(:to_h)

      raw = raw.to_h.symbolize_keys
      percent = parse_percent(raw[:percent])
      return unless percent

      new(quote: parse_quote(raw[:quote]), block_index: parse_block_index(raw[:block_index]), percent:,
          digest: parse_digest(raw[:digest]))
    end

    def self.parse_quote(value)
      value.is_a?(String) ? value.squish.first(QUOTE_LENGTH).presence : nil
    end

    def self.parse_block_index(value)
      index = Integer(value, exception: false) if value.is_a?(Integer) || value.is_a?(String)
      index if index&.between?(0, MAX_BLOCK_INDEX)
    end

    def self.parse_percent(value)
      percent = Float(value, exception: false) if value.is_a?(Numeric) || value.is_a?(String)
      percent.round(2) if percent&.finite? && percent.between?(0, 100)
    end

    def self.parse_digest(value)
      value if value.is_a?(String) && value.match?(DIGEST_FORMAT)
    end

    private_class_method :parse_quote, :parse_block_index, :parse_percent, :parse_digest

    def initialize(quote:, block_index:, percent:, digest:)
      @quote = quote
      @block_index = block_index
      @percent = percent
      @digest = digest
    end

    def attributes
      { resume_quote: quote, resume_block_index: block_index, resume_percent: percent, resume_digest: digest }
    end
  end
end
