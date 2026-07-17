# frozen_string_literal: true

module Books
  # Picks the smallest fiction cover attachment (some records have duplicate huge PNGs).
  module EpubCoverAttachment
    module_function

    def smallest_for(fiction)
      ActiveStorage::Attachment
        .includes(:blob)
        .where(record: fiction, name: 'cover')
        .min_by { |attachment| attachment.blob.byte_size }
    end
  end
end
