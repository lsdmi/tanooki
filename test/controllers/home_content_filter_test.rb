# frozen_string_literal: true

require 'test_helper'

class HomeContentFilterTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @eighteen = fictions(:eighteen)
    @everyone = fictions(:one)
    Rails.cache.write('hot_updates_ids', [@eighteen.id, @everyone.id])
    Rails.cache.write(Fictions::IndexVariablesManager::LATEST_UPDATES_IDS_CACHE_KEY, [@eighteen.id, @everyone.id])
  end

  teardown do
    Rails.cache.delete('hot_updates_ids')
    Rails.cache.delete(Fictions::IndexVariablesManager::LATEST_UPDATES_IDS_CACHE_KEY)
  end

  test 'home hides an 18+ fiction when the account cap is 16' do
    sign_in users(:user_one)

    Search::TagCounts.stub(:call, {}) { get root_path }

    assert_select '[aria-label="Популярне ранобе"] a', text: @eighteen.title, count: 0
    assert_select '[aria-label="Популярне ранобе"] a', text: @everyone.title, minimum: 1
    assert_includes response.body, I18n.t('content_filters.hidden_count', count: 1)
  end

  test 'home keeps an 18+ fiction when the reader is open' do
    Search::TagCounts.stub(:call, {}) { get root_path }

    assert_select '[aria-label="Популярне ранобе"] a', text: @eighteen.title, minimum: 1
    assert_not_includes response.body, I18n.t('content_filters.some_hidden')
  end
end
