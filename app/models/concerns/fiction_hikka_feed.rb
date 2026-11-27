# frozen_string_literal: true

# Expires the cached Hikka list when a field it shows changes, so a new Hikka link or title reaches Hikka before
# the hour is up. Other edits (views, chapter counts, listing) leave the cache alone: the list is costly to rebuild.
module FictionHikkaFeed
  extend ActiveSupport::Concern

  # The columns as_hikka_json reads, plus deleted_at (a deleted fiction leaves the list).
  FEED_COLUMNS = %w[title alternative_title english_title description slug hikka_slug deleted_at].freeze

  included do
    after_save :mark_hikka_feed_stale, if: :hikka_feed_changed?
    after_destroy :mark_hikka_feed_stale
    after_commit :bust_hikka_feed
    after_rollback :forget_hikka_feed_stale
  end

  private

  # Runs inside the save transaction: the cover upload is still pending in attachment_changes here.
  def hikka_feed_changed?
    saved_changes.keys.intersect?(FEED_COLUMNS) || attachment_changes.key?('cover')
  end

  def mark_hikka_feed_stale
    @hikka_feed_stale = true
  end

  # Waits for the commit, so a rolled-back save (or a DRY_RUN merge) leaves the cache as it was.
  def bust_hikka_feed
    return unless @hikka_feed_stale

    @hikka_feed_stale = false
    Fictions::HikkaFeed.bust
  end

  def forget_hikka_feed_stale
    @hikka_feed_stale = false
  end
end
