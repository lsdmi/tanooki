# frozen_string_literal: true

require 'test_helper'

class EpubExportRequestReuseTest < ActiveSupport::TestCase
  setup do
    @user = users(:user_one)
    @rich_text_ids = [action_text_rich_texts(:rich_text_four).id]
  end

  test 'content_fingerprint is stable for id order' do
    assert_equal EpubExportRequest.content_fingerprint([3, 1, 2]),
                 EpubExportRequest.content_fingerprint([2, 3, 1])
  end

  test 'content_fingerprint differs when volume title differs' do
    base = EpubExportRequest.content_fingerprint(@rich_text_ids)
    titled = EpubExportRequest.content_fingerprint(@rich_text_ids, 'Том 1')

    assert_not_equal base, titled
  end

  test 'find_reusable_for returns ready export with attached file' do
    original = create_ready_export

    found = EpubExportRequest.find_reusable_for(
      user: @user,
      rich_text_ids: @rich_text_ids
    )

    assert_equal original.id, found.id
  end

  test 'find_reusable_for does not return failed export' do
    EpubExportRequest.create!(
      user: @user,
      rich_text_ids: @rich_text_ids,
      status: :failed,
      error_message: 'boom'
    )

    assert_nil EpubExportRequest.find_reusable_for(user: @user, rich_text_ids: @rich_text_ids)
  end

  test 'find_reusable_for does not return expired export' do
    export = EpubExportRequest.create!(
      user: @user,
      rich_text_ids: @rich_text_ids,
      status: :ready,
      filename: 'book.epub',
      expires_at: 1.hour.ago
    )
    attach_epub(export)

    assert_nil EpubExportRequest.find_reusable_for(user: @user, rich_text_ids: @rich_text_ids)
  end

  test 'find_reusable_for does not return stale processing export' do
    export = nil

    travel_to 31.minutes.ago do
      export = EpubExportRequest.create!(
        user: @user,
        rich_text_ids: @rich_text_ids,
        status: :processing
      )
    end

    assert_nil EpubExportRequest.find_reusable_for(user: @user, rich_text_ids: @rich_text_ids)

    export.reload

    assert_predicate export, :failed?
    assert_equal I18n.t('downloads.epub_export.generation_interrupted'), export.error_message
  end

  private

  def create_ready_export(**attrs)
    export = EpubExportRequest.create!(
      {
        user: @user,
        rich_text_ids: @rich_text_ids,
        status: :ready,
        filename: 'book.epub'
      }.merge(attrs)
    )
    attach_epub(export)
    export
  end

  def attach_epub(export)
    export.file.attach(
      io: StringIO.new('epub-bytes'),
      filename: 'book.epub',
      content_type: 'application/epub+zip',
      identify: false
    )
  end
end
