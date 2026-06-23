# frozen_string_literal: true

# Shared ActiveRecord `normalizes` helpers for string cleanup on assignment.
module NormalizesWhitespace
  extend ActiveSupport::Concern

  class_methods do
    def normalizes_squished(*attributes)
      attributes.each do |attribute|
        normalizes attribute, with: ->(value) { value.squish }, apply_to_nil: false
      end
    end

    def normalizes_stripped(*attributes)
      attributes.each do |attribute|
        normalizes attribute, with: ->(value) { value.strip }, apply_to_nil: false
      end
    end
  end
end
