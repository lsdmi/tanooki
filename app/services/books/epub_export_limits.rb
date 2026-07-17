# frozen_string_literal: true

module Books
  # Guards EPUB exports that exceed safe in-worker source size (Action Text body bytes).
  class EpubExportLimits
    MAX_SOURCE_BYTES = 45.megabytes

    def self.source_bytes(rich_text_ids)
      ActionText::RichText.where(id: Array(rich_text_ids)).sum('LENGTH(body)')
    end

    def self.too_large?(rich_text_ids)
      source_bytes(rich_text_ids) > MAX_SOURCE_BYTES
    end

    def self.blocked_by_missing_vips?(rich_text_ids)
      data_uri_images?(rich_text_ids) && !Attachments::VariantProcessing.available?
    end

    def self.data_uri_images?(rich_text_ids)
      ActionText::RichText
        .where(id: Array(rich_text_ids))
        .exists?(['body LIKE ?', '%data:image%base64,%'])
    end
  end
end
