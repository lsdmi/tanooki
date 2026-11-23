# frozen_string_literal: true

module Fictions
  # Tag half of FictionForm: rejects bad submitted names before the fiction is written and keeps the
  # submitted choice on the fiction so a failed save shows it again (like genre_ids). Saving the links
  # happens afterwards in FictionTags::Sync, once the fiction has an id.
  module FormTags
    extend ActiveSupport::Concern

    included do
      validate :tag_names_are_valid
    end

    private

    def assign_tag_names
      fiction.tag_names = Array(params[:tag_names]).compact_blank if param?(:tag_names)
    end

    def tag_names_are_valid
      return unless param?(:tag_names)

      FictionTags::Sync.check(params[:tag_names]).each do |error|
        errors.add(:tag_names, tag_error_message(error))
      end
    end

    def tag_error_message(error)
      I18n.t(error.code, scope: 'fictions.form.tags.errors', name: error.name,
                         max_tags: FictionTag::MAX_PER_FICTION, max_length: FictionTag::MAX_NAME_LENGTH)
    end
  end
end
