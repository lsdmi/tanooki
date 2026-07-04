# frozen_string_literal: true

require 'test_helper'

module Root
  class HeroCopyTest < ActiveSupport::TestCase
    test 'guest copy includes full and compact body' do
      copy = HeroCopy.for(signed_in: false)

      assert_includes copy[:body], 'єство життя'
      assert_includes copy[:body_compact], 'братерства'
      assert_operator copy[:body_compact].length, :<, copy[:body].length
    end

    test 'signed-in copy includes full and compact body' do
      copy = HeroCopy.for(signed_in: true)

      assert_includes copy[:body], 'бодай цей вечір'
      assert_includes copy[:body_compact], 'відшукай нові'
      assert_operator copy[:body_compact].length, :<, copy[:body].length
    end
  end
end
