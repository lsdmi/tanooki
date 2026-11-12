# frozen_string_literal: true

module Chapters
  # Creates an open paragraph error report for a live chapter. The team (and admins) cannot report their own work.
  class CreateParagraphReport
    Result = Data.define(:ok, :report, :error)

    QUOTE_MAX = ParagraphReport::QUOTE_MAX
    MESSAGE_MAX = ParagraphReport::MESSAGE_MAX
    DIGEST_LENGTH = ParagraphReport::DIGEST_LENGTH

    def self.call(...) = new(...).call

    def initialize(chapter:, user:, attrs:)
      @chapter = chapter
      @user = user
      @attrs = attrs.to_h.symbolize_keys
    end

    def call
      return failure(:not_released) unless @chapter.public_visible?
      return failure(:own_work) if @user.manages_chapter?(@chapter)

      payload = validated_payload
      return payload if payload.is_a?(Result)

      create_open!(payload)
    rescue ActiveRecord::RecordNotUnique
      failure(:duplicate_open)
    end

    private

    def validated_payload
      index = parse_block_index
      return failure(:invalid_anchor) if index.nil?

      quote = normalize_quote(@attrs[:quote])
      return failure(:blank_quote) if quote.blank?

      digest_payload(index, quote)
    end

    def digest_payload(index, quote)
      digest = @attrs[:digest].to_s
      return failure(:invalid_anchor) if digest.length != DIGEST_LENGTH

      message = normalize_message(@attrs[:message])
      return failure(:message_too_long) if message && message.length > MESSAGE_MAX

      { block_index: index, quote:, digest:, message: }
    end

    def create_open!(payload)
      @chapter.with_lock do
        if ParagraphReport.open.exists?(user: @user, chapter: @chapter, **payload.slice(:block_index, :digest))
          return failure(:duplicate_open)
        end

        success(ParagraphReport.create!(user: @user, chapter: @chapter, status: :open, **payload))
      end
    end

    def parse_block_index
      Integer(@attrs[:block_index]).then { |index| index.negative? ? nil : index }
    rescue ArgumentError, TypeError
      nil
    end

    def normalize_quote(value)
      value.to_s.gsub(/\s+/, ' ').strip.slice(0, QUOTE_MAX)
    end

    def normalize_message(value)
      value.to_s.strip.presence
    end

    def success(report) = Result.new(ok: true, report:, error: nil)

    def failure(error) = Result.new(ok: false, report: nil, error:)
  end
end
