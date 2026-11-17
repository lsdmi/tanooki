# frozen_string_literal: true

require 'test_helper'

class PagesCreditsTest < ActionDispatch::IntegrationTest
  test 'footer omits hand-drawn icon credit' do
    Search::TagCounts.stub(:call, {}) do
      get root_url
    end

    assert_select 'footer', text: /Hand-Drawn Goods/, count: 0
  end

  test 'about page credits hand-drawn nav icons' do
    get about_url

    assert_select '#credits h2', text: 'Подяки'
    assert_select '#credits a[href=?]', 'https://handdrawngoods.com/', text: 'Hand-Drawn Goods'
    assert_select '#credits a[href=?]', 'https://creativecommons.org/licenses/by/4.0/', text: 'CC BY'
  end
end
