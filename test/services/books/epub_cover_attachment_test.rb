# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubCoverAttachmentTest < ActiveSupport::TestCase
    test 'smallest_for returns attachment with smallest blob byte size' do
      fiction = fictions(:one)
      large = fiction.cover.blob
      small_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('small'),
        filename: 'small.webp',
        content_type: 'image/webp'
      )
      ActiveStorage::Attachment.create!(name: 'cover', record: fiction, blob: small_blob)

      chosen = EpubCoverAttachment.smallest_for(fiction)

      assert_equal small_blob.id, chosen.blob_id
      assert_operator chosen.blob.byte_size, :<, large.byte_size
    end
  end
end
