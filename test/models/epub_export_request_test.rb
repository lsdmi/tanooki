# frozen_string_literal: true

require 'test_helper'

class EpubExportRequestTest < ActiveSupport::TestCase
  test 'assigns token and expiry on create' do
    export_request = EpubExportRequest.create!(rich_text_ids: [action_text_rich_texts(:rich_text_four).id])

    assert_predicate export_request.token, :present?
    assert_predicate export_request.expires_at, :future?
    assert_predicate export_request, :queued?
  end

  test 'downloadable requires ready status attached file and active expiry' do
    export_request = EpubExportRequest.create!(rich_text_ids: [action_text_rich_texts(:rich_text_four).id])

    assert_not_predicate export_request, :downloadable?
  end

  test 'status_label returns ukrainian status text' do
    export_request = EpubExportRequest.create!(rich_text_ids: [action_text_rich_texts(:rich_text_four).id])

    assert_equal 'У черзі', export_request.status_label
  end
end
