# frozen_string_literal: true

module Chapters
  # Shrinks oversized inline images in a chapter rich text body and persists it.
  class CompressInlineImages
    Result = Data.define(
      :chapter_id, :rich_text_id, :images_compressed, :before_bytes, :after_bytes, :unchanged,
      :skipped_reason
    ) do
      def initialize(skipped_reason: nil, **) = super
    end

    # Pass max_body_bytes: nil to compress oversized bodies outside the job container.
    def self.call(chapter_id, max_body_bytes: ContentLimits::MAX_AUTOMATED_COMPRESS_BODY_BYTES)
      new(chapter_id, max_body_bytes:).call
    end

    def initialize(chapter_id, max_body_bytes: ContentLimits::MAX_AUTOMATED_COMPRESS_BODY_BYTES)
      @chapter_id = chapter_id.to_i
      @max_body_bytes = max_body_bytes
    end

    def call
      ensure_vips!
      rich_text = find_rich_text!
      html = rich_text.read_attribute_before_type_cast(:body).to_s
      return oversized_result(rich_text.id, html) if oversized?(html)

      compress(rich_text.id, html)
    end

    private

    def compress(rich_text_id, html)
      compression = InlineImagesCompressor.compress(html)
      return unchanged_result(rich_text_id, compression) if compression.images_compressed.zero?

      persist!(rich_text_id, compression.html)
      build_result(rich_text_id, compression, unchanged: false)
    end

    def oversized?(html)
      @max_body_bytes.present? && html.bytesize > @max_body_bytes
    end

    def oversized_result(rich_text_id, html)
      Rails.logger.warn(
        "[CompressInlineImages] chapter=#{@chapter_id} skipped: body #{html.bytesize} bytes " \
        "exceeds the #{@max_body_bytes} byte automated limit"
      )
      Result.new(
        chapter_id: @chapter_id, rich_text_id: rich_text_id, images_compressed: 0,
        before_bytes: html.bytesize, after_bytes: html.bytesize, unchanged: true,
        skipped_reason: :body_too_large
      )
    end

    def ensure_vips!
      return if Attachments::VariantProcessing.available?

      raise ArgumentError, I18n.t('downloads.epub_export.image_processing_unavailable')
    end

    def find_rich_text!
      ActionText::RichText.find_by!(record_type: 'Chapter', record_id: @chapter_id, name: 'content')
    end

    def persist!(rich_text_id, html)
      # Intentionally bypasses validations; this repair job shrinks legacy oversized bodies.
      ActionText::RichText.where(id: rich_text_id).update_all( # rubocop:disable Rails/SkipsModelValidations
        body: html,
        updated_at: Time.current
      )
      Chapter.where(id: @chapter_id).update_all(updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end

    def unchanged_result(rich_text_id, compression)
      build_result(rich_text_id, compression, unchanged: true)
    end

    def build_result(rich_text_id, compression, unchanged:)
      Result.new(
        chapter_id: @chapter_id,
        rich_text_id: rich_text_id,
        images_compressed: compression.images_compressed,
        before_bytes: compression.before_bytes,
        after_bytes: compression.after_bytes,
        unchanged: unchanged
      )
    end
  end
end
