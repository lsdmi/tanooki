# frozen_string_literal: true

# Folds the guest reading records kept on this device into the account after sign-in (P3.2).
# `guest-reading-merge` posts them and clears them from the device once this answers 200.
# Records that can't be used (a deleted fiction, chapters the user can't list) are skipped, not rejected, so the
# device never retries them forever.
class GuestReadingMergesController < ApplicationController
  MAX_RECORDS = 200
  RECORD_KEYS = [:fiction_id, :chapter_id, :resume_at,
                 { read_chapter_ids: [], locator: Chapters::ReadingEvents::LOCATOR_KEYS }].freeze

  wrap_parameters false
  before_action :authenticate_user!
  rate_limit to: 20, within: 1.minute

  def create
    records = guest_records
    return head(:unprocessable_content) unless records

    merged = records.count { |record| Reading::MergeGuestRecord.new(user: current_user, record:).call }
    render json: { merged: }
  end

  private

  def guest_records
    raw = params.permit(records: RECORD_KEYS)[:records]
    raw.first(MAX_RECORDS).filter_map { Reading::GuestRecord.parse(it) } if raw.is_a?(Array)
  end
end
