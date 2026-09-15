# frozen_string_literal: true

module Chapters
  # Creates or updates a chapter from composer intent (draft vs publish).
  class Persist
    DRAFT_INTENT = 'draft'
    PUBLISH_INTENT = 'publish'

    def self.call(...)
      new(...).call
    end

    def self.normalize_intent(intent)
      intent.to_s == DRAFT_INTENT ? DRAFT_INTENT : PUBLISH_INTENT
    end

    def initialize(chapter:, attributes:, intent:, user:)
      @chapter = chapter
      @attributes = attributes
      @intent = self.class.normalize_intent(intent)
      @user = user
    end

    def call
      previous_status = chapter.status
      assign_and_apply_intent
      if chapter.save
        after_save
        true
      else
        rollback_status(previous_status)
        false
      end
    end

    private

    attr_reader :chapter, :attributes, :intent, :user

    def assign_and_apply_intent
      allow_draft = chapter.new_record? || chapter.draft?
      chapter.assign_attributes(attributes)
      apply_intent(allow_draft:)
    end

    def after_save
      sync_scanlators
      Catalog::RefreshChapterStats.call(chapter.fiction.reload)
    end

    def rollback_status(previous_status)
      chapter.status = previous_status if chapter.persisted?
    end

    def apply_intent(allow_draft:)
      if intent == DRAFT_INTENT && allow_draft
        chapter.status = :draft
        chapter.published_at = nil
      else
        chapter.status = :published
      end
    end

    def sync_scanlators
      SyncScanlatorAssociations.new(attributes[:scanlator_ids], chapter, user: user).call
      LinkFictionScanlators.call(chapter:)
    end
  end
end
