# frozen_string_literal: true

module Publications
  # Creates or updates a blog from composer intent (draft vs publish).
  class Persist
    DRAFT_INTENT = 'draft'
    PUBLISH_INTENT = 'publish'

    def self.call(...)
      new(...).call
    end

    def self.normalize_intent(intent)
      intent.to_s == DRAFT_INTENT ? DRAFT_INTENT : PUBLISH_INTENT
    end

    def initialize(publication:, attributes:, intent:)
      @publication = publication
      @attributes = attributes
      @intent = self.class.normalize_intent(intent)
    end

    def call
      previous_status = publication.status
      assign_and_apply_intent
      if publication.save
        after_save
        true
      else
        rollback_status(previous_status)
        false
      end
    end

    private

    attr_reader :publication, :attributes, :intent

    def assign_and_apply_intent
      was_draft = publication.draft?
      publication.assign_attributes(attributes)
      apply_intent(was_draft:)
      apply_placeholder_title if publication.draft?
    end

    def rollback_status(previous_status)
      return unless publication.persisted?

      publication.status = previous_status
      publication.published_at = publication.published_at_was
    end

    def after_save
      PublicCache.bust(publication)
    end

    def apply_intent(was_draft:)
      if intent == DRAFT_INTENT
        publication.status = :draft
        publication.published_at = nil
      else
        publication.status = :published
        stamp_release(was_draft:)
      end
    end

    # A sketch published later gets the moment it went live. Editing a live post keeps that time.
    def stamp_release(was_draft:)
      return if publication.published_at.present?
      return unless was_draft || publication.new_record?

      publication.published_at = Time.current
    end

    def apply_placeholder_title
      publication.title = I18n.t('publications.placeholder_title') if publication.title.blank?
    end
  end
end
