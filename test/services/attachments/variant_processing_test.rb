# frozen_string_literal: true

require 'test_helper'

module Attachments
  class VariantProcessingTest < ActiveSupport::TestCase
    teardown do
      VariantProcessing.reset!
    end

    test 'available? reflects whether libvips is installed' do
      if VariantProcessing.vips_available?
        assert_predicate VariantProcessing, :available?
      else
        assert_not VariantProcessing.available?
      end
    end
  end
end
