# frozen_string_literal: true

module Attachments
  # Detects whether Active Storage can transform image variants on this host.
  module VariantProcessing
    module_function

    def available?
      return @available unless @available.nil?

      @available = vips_available?
    end

    def reset!
      @available = nil
    end

    def vips_available?
      require 'vips'

      Vips.at_least_libvips?(8, 0)
    rescue LoadError, StandardError
      false
    end
  end
end
