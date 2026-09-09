# frozen_string_literal: true

module Catalog
  # Editorial listing fields from the fiction form: expected length and complete checkbox.
  # Does not persist; the caller saves so validations stay on the listing.
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
      apply_complete if @fields.key?(:complete)
      @listing
    end

    private

    def normalize_expected(expected)
      return if expected.blank?

      expected
    end

    def apply_complete
      if complete?
        @listing.completed_at ||= Time.current
      else
        @listing.completed_at = nil
      end
    end

    def complete?
      ActiveModel::Type::Boolean.new.cast(@fields[:complete])
    end
  end
end
