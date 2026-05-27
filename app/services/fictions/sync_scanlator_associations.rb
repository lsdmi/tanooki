# frozen_string_literal: true

module Fictions
  # Creates and removes scanlator links on a fiction.
  # Non-admin editors only change teams they belong to; other teams on the fiction stay linked.
  class SyncScanlatorAssociations
    attr_reader :scanlators_ids, :fiction, :user

    def initialize(scanlators_ids, fiction, user: nil)
      @scanlators_ids = scanlators_ids
      @fiction = fiction
      @user = user
    end

    def call
      return if scanlators_ids.nil?

      create_fiction_scanlators
      destroy_fiction_scanlators
    end

    private

    def create_fiction_scanlators
      scanlators_to_add = effective_scanlator_ids - existing_scanlators_ids
      scanlators_to_add.each { |scanlator_id| fiction.fiction_scanlators.create(scanlator_id:) }
    end

    def destroy_fiction_scanlators
      scanlators_to_remove = existing_scanlators_ids - effective_scanlator_ids
      scanlators_to_remove.each { |scanlator_id| fiction.fiction_scanlators.find_by(scanlator_id:).destroy }
    end

    def existing_scanlators_ids
      fiction.scanlators.ids
    end

    def submitted_scanlator_ids
      scanlators_ids.reject(&:empty?).map(&:to_i)
    end

    def effective_scanlator_ids
      return submitted_scanlator_ids if user.nil? || user.admin?

      manageable_ids = user.scanlators.ids
      preserved_ids = existing_scanlators_ids - manageable_ids
      (preserved_ids + submitted_scanlator_ids).uniq
    end
  end
end
