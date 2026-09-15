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
      allow_draft = publication.new_record? || publication.draft?
      publication.assign_attributes(attributes)
      apply_intent(allow_draft:)
      apply_placeholder_title if publication.draft?
    end

    def rollback_status(previous_status)
      publication.status = previous_status if publication.persisted?
    end

    def after_save
      PublicCache.bust(publication)
    end

    def apply_intent(allow_draft:)
      publication.status = intent == DRAFT_INTENT && allow_draft ? :draft : :published
    end

    def apply_placeholder_title
      publication.title = I18n.t('publications.placeholder_title') if publication.title.blank?
    end
  end
end
