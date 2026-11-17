# frozen_string_literal: true

require 'test_helper'

class FictionsIndexAccessibilityTest < ActionDispatch::IntegrationTest
  test 'section more-links expose their label when the visible text is screen-reader only' do
    get fictions_path

    assert_select "a[href='#{alphabetical_fictions_path}'] .sr-only", text: /Більше/
  end

  test 'buy-me-a-coffee icon is decorative inside the named footer social link' do
    get fictions_path
    coffee = 'footer nav[aria-label="Соцмережі"] a[href="https://www.buymeacoffee.com/bakaInUa"]'

    assert_select "#{coffee}[aria-label]"
    assert_select "#{coffee} svg[aria-hidden='true']"
    assert_select "#{coffee} svg[role='img']", count: 0
  end

  test 'navbar toolbar omits telegram github and buymeacoffee links' do
    get fictions_path

    assert_select 'nav.bg-main a[aria-label="Telegram"]', count: 0
    assert_select 'nav.bg-main a[href="https://github.com/lsdmi/tanooki"]', count: 0
    assert_select 'nav.bg-main a[href="https://www.buymeacoffee.com/bakaInUa"]', count: 0
  end
end
