# frozen_string_literal: true

require 'test_helper'

class TaleTest < ActiveSupport::TestCase
  setup do
    @tale = publications(:tale_approved_one)
  end
end
