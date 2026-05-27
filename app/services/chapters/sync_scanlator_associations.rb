# frozen_string_literal: true

module Chapters
  # Creates and removes scanlator links on a chapter.
  # Non-admin editors only change teams they belong to; other teams on the chapter stay linked.
  class SyncScanlatorAssociations
    attr_reader :scanlators_ids, :chapter, :user

    def initialize(scanlators_ids, chapter, user: nil)
      @scanlators_ids = scanlators_ids
      @chapter = chapter
      @user = user
    end

    def call
      return if scanlators_ids.nil?

      create_chapter_scanlators
      destroy_chapter_scanlators
    end

    private

    def create_chapter_scanlators
      scanlators_to_add = effective_scanlator_ids - existing_scanlators_ids
      scanlators_to_add.each { |scanlator_id| chapter.chapter_scanlators.create(scanlator_id:) }
    end

    def destroy_chapter_scanlators
      scanlators_to_remove = existing_scanlators_ids - effective_scanlator_ids
      scanlators_to_remove.each { |scanlator_id| chapter.chapter_scanlators.find_by(scanlator_id:).destroy }
    end

    def existing_scanlators_ids
      chapter.scanlators.ids
    end

    def submitted_scanlator_ids
      scanlators_ids.reject(&:empty?).map(&:to_i)
    end

    def effective_scanlator_ids
      return submitted_scanlator_ids if user.nil? || user.admin?

      manageable_ids = user.scanlators.ids
      preserved_ids = existing_scanlators_ids - manageable_ids
      allowed_submitted = allowed_scanlator_ids_for_user(manageable_ids)
      (preserved_ids + allowed_submitted).uniq
    end

    def allowed_scanlator_ids_for_user(manageable_ids)
      foreign_submitted = submitted_scanlator_ids - manageable_ids
      if foreign_submitted.any?
        existing_scanlators_ids & manageable_ids
      else
        submitted_scanlator_ids & manageable_ids
      end
    end
  end
end
