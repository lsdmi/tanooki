# frozen_string_literal: true

require 'test_helper'

module Fictions
  class LicensedTagComponentTest < ViewComponent::TestCase
    setup do
      @fiction = fictions(:one)
    end

    test 'a licensed work gets the tag' do
      @fiction.licensed_at = 1.day.ago

      render_inline(LicensedTagComponent.new(fiction: @fiction))

      assert_selector 'span', text: 'Ліцензовано'
    end

    test 'an unlicensed work gets nothing' do
      render_inline(LicensedTagComponent.new(fiction: @fiction))

      assert_no_selector 'span'
    end
  end
end
