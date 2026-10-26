# frozen_string_literal: true

module Catalog
  # Editorial listing fields from the fiction form: expected length and release.
  # Does not persist; the caller saves so validations stay on the listing.
  # `complete:` stays for listing nudges. A licensed listing ignores `release: paused`.
  class UpdateListingEditorial
    def self.call(listing, **fields)
      new(listing, **fields).call
    end

    def initialize(listing, **fields)
      @listing = listing
      @fields = fields
    end

    def call
      @listing.expected_chapters = normalize_expected(@fields[:expected]) if @fields.key?(:expected)
      apply_release if @fields.key?(:release)
      apply_complete if @fields.key?(:complete)
      @listing
    end

    private

    def normalize_expected(expected)
      return if expected.blank?

      expected
    end

    def apply_release
      case @fields[:release].to_s
      when 'ongoing' then clear_release
      when 'paused' then pause_release
      when 'finished' then finish_release
      end
    end

    def clear_release
      @listing.paused_at = nil
      @listing.completed_at = nil
    end

    def pause_release
      return if @listing.licensed?

      @listing.paused_at ||= Time.current
      @listing.completed_at = nil
    end

    def finish_release
      @listing.completed_at ||= Time.current
      @listing.paused_at = nil
    end

    def apply_complete
      if complete?
        @listing.completed_at ||= Time.current
        @listing.paused_at = nil
      else
        @listing.completed_at = nil
      end
    end

    def complete?
      ActiveModel::Type::Boolean.new.cast(@fields[:complete])
    end
  end
end
