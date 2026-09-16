# frozen_string_literal: true

require 'test_helper'

class FictionsIndexAccessibilityTest < ActionDispatch::IntegrationTest
  test 'section more-links expose their label when the visible text is screen-reader only' do
    get fictions_path

    assert_select "a[href='#{alphabetical_fictions_path}'] .sr-only", text: /Більше/
  end

  test 'buy-me-a-coffee icon is decorative inside the named navbar link' do
    get fictions_path

    assert_select 'a[href="https://www.buymeacoffee.com/bakaInUa"][aria-label]'
    assert_select 'a[href="https://www.buymeacoffee.com/bakaInUa"] svg[aria-hidden="true"]'
    assert_select 'a[href="https://www.buymeacoffee.com/bakaInUa"] svg[role="img"]', count: 0
  end
end
