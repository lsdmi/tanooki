# frozen_string_literal: true

module Attachments
  # Detects whether Active Storage can transform image variants on this host.
  module VariantProcessing
    module_function

    def available?
      return @available unless @available.nil?

      @available = vips_available?
    end

    # False for a blob on a service this environment must not write to (ReadOnlyStorage): its variant could not be
    # stored, so callers show the original.
    def processable?(blob)
      blob.variable? && available? && !ReadOnlyStorage.covers?(blob.service_name)
    end

    def reset!
      @available = nil
    end

    def vips_available?
      require 'vips'

      Vips.at_least_libvips?(8, 13)
    rescue LoadError, StandardError
      false
    end
  end
end
