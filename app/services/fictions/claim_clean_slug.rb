# frozen_string_literal: true

module Fictions
  # When a fiction's slug still has the UUID friendly_id appended and the clean slug is free,
  # take the clean slug and leave the UUID slug as a merged redirect.
  class ClaimCleanSlug
    UUID_SUFFIX = /-([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\z/

    def initialize(fiction)
      @fiction = fiction
    end

    def call
      clean = available_clean_slug
      return fiction unless clean

      old_slug = fiction.slug
      Fiction.transaction do
        fiction.update!(slug: clean)
        remember_old_slug(old_slug)
      end
      fiction
    rescue ActiveRecord::RecordNotUnique
      fiction.reload
    end

    private

    attr_reader :fiction

    def available_clean_slug
      return if fiction.deleted?

      match = fiction.slug.to_s.match(UUID_SUFFIX)
      return unless match

      clean = fiction.slug.sub(UUID_SUFFIX, '')
      return if clean.blank? || Fiction.with_deleted.exists?(slug: clean)

      clean
    end

    def remember_old_slug(old_slug)
      redirect = fiction.dup
      redirect.slug = old_slug
      redirect.merged_into = fiction
      redirect.deleted_at = Time.current
      redirect.save!(validate: false)
    end
  end
end
