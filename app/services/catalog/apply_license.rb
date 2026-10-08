# frozen_string_literal: true

module Catalog
  # Official license fields from the fiction form: the licensed checkbox, publisher and store URL.
  # Does not persist; the caller saves. Saving a newly licensed fiction reverts its scheduled
  # chapters to drafts (FictionLicense). Clearing follows Fiction#license_clearable_by?:
  # the team within the grace period, an admin at any time. Reverted drafts stay drafts.
  # `hidden` (admin only) hides every chapter past the preview; clearing the license unhides them.
  class ApplyLicense
    def self.call(fiction, actor:, **fields)
      new(fiction, actor:, **fields).tap(&:call)
    end

    def initialize(fiction, actor:, **fields)
      @fiction = fiction
      @actor = actor
      @fields = fields
      @clear_denied = false
    end

    def call
      return @fiction unless @fields.key?(:licensed)

      licensed? ? mark : clear
      @fiction
    end

    def clear_denied?
      @clear_denied
    end

    private

    def mark
      @fiction.licensed_at ||= Time.current
      @fiction.license_publisher = @fields[:publisher] if @fields.key?(:publisher)
      @fiction.license_url = @fields[:url] if @fields.key?(:url)
      hide_chapters if @fields.key?(:hidden) && @actor&.admin?
    end

    def hide_chapters
      hidden = ActiveModel::Type::Boolean.new.cast(@fields[:hidden])
      @fiction.chapters_hidden_at = hidden ? @fiction.chapters_hidden_at || Time.current : nil
    end

    def clear
      return unless @fiction.licensed?
      return @clear_denied = true unless @fiction.license_clearable_by?(@actor)

      @fiction.assign_attributes(licensed_at: nil, license_publisher: nil, license_url: nil, chapters_hidden_at: nil)
    end

    def licensed?
      ActiveModel::Type::Boolean.new.cast(@fields[:licensed])
    end
  end
end
