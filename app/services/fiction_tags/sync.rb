# frozen_string_literal: true

module FictionTags
  # Replaces a fiction's tag links with the submitted tag names (same idea as Fictions::SyncGenres).
  # Unknown names become new active tags. All or nothing: any error rolls back new tags and links.
  # Hidden tags are never newly attached, but a fiction that already carries one keeps it.
  class Sync
    Error = Data.define(:code, :name)
    Result = Data.define(:tags, :errors) do
      def success? = errors.empty?
    end

    def self.call(fiction, names: nil)
      new(fiction, names:).call
    end

    # Name-only validation with no database access, so a form can reject bad input before saving the fiction.
    def self.check(names)
      valid, errors = screen(names)
      valid.size > FictionTag::MAX_PER_FICTION ? errors + [Error.new(:too_many_tags, nil)] : errors
    end

    # Splits submitted names into unique valid names and one error per unusable name.
    def self.screen(names)
      normalized = Array(names).map { |name| Normalizer.name(name) }.compact_blank
      invalid, valid = normalized.partition { |name| name_error(name) }
      [Normalizer.unique_names(valid), invalid.map { |name| name_error(name) }]
    end

    def self.name_error(name)
      return Error.new(:invalid, name) if Normalizer.slug(name).blank?

      Error.new(:too_long, name) if name.length > FictionTag::MAX_NAME_LENGTH
    end

    def initialize(fiction, names:)
      @fiction = fiction
      @names = names
      @errors = []
    end

    def call
      return result if @names.nil?

      FictionTag.transaction do
        desired = desired_tags
        @errors << Error.new(:too_many_tags, nil) if desired.size > FictionTag::MAX_PER_FICTION
        raise ActiveRecord::Rollback if @errors.any?

        write_links(desired.map(&:id))
      end
      result
    end

    private

    def result
      Result.new(tags: @fiction.fiction_tags.reset.to_a, errors: @errors)
    end

    def desired_tags
      tags_by_name.uniq(&:id).select { |tag| tag.active? || current_ids.include?(tag.id) }
    end

    def tags_by_name
      valid, errors = self.class.screen(@names)
      @errors.concat(errors)
      valid.filter_map { |name| find_or_create(name) }
    end

    def find_or_create(name)
      FictionTag.find_by(slug: Normalizer.slug(name)) || FictionTag.find_by(name:) || create_tag(name)
    end

    def create_tag(name)
      tag = FictionTag.create(name:)
      return tag if tag.persisted?

      @errors << Error.new(tag.errors.details[:name].first[:error], name)
      nil
    rescue ActiveRecord::RecordNotUnique
      FictionTag.find_by!(slug: Normalizer.slug(name))
    end

    def current_ids
      @current_ids ||= @fiction.fiction_tag_links.pluck(:fiction_tag_id)
    end

    def write_links(desired_ids)
      removed = current_ids - desired_ids
      added = desired_ids - current_ids
      @fiction.fiction_tag_links.where(fiction_tag_id: removed).destroy_all
      added.each { |tag_id| @fiction.fiction_tag_links.create!(fiction_tag_id: tag_id) }
      # Search indexes tags off the fiction row (Phase 6), so a tag edit has to save it or search stays stale.
      @fiction.update!(updated_at: Time.current) if removed.any? || added.any?
    end
  end
end
