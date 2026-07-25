# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'should get rules' do
    get rules_url

    assert_response :success
  end

  test 'should get friends' do
    get friends_url

    assert_response :success
    assert_select 'h1', text: 'Друзі Баки'
  end

  test 'friends page renders section headings' do
    get friends_url

    assert_select 'h2', text: /Перегляд|Манґа|Аніме|Підтримка/, count: 4
  end

  test 'friends page links to Save Life fund' do
    get friends_url

    assert_select 'a[href="https://savelife.in.ua/donate/"]', text: /Повернись живим/
  end

  test 'friends page includes telegram community CTA' do
    get friends_url

    assert_select 'aside[aria-label=?]', 'Стань нашим другом'
    assert_select 'aside a[href=?]', ExternalUrls.site_url, text: 'Спільнота'
  end

  test 'footer includes friends link' do
    Search::TagCounts.stub(:call, {}) do
      get root_url
    end

    assert_select 'footer nav a[href=?]', friends_path, text: 'Друзі'
  end

  test 'should get privacy' do
    get privacy_url

    assert_response :success
  end

  test 'privacy-policy slug redirects to privacy for crawlers' do
    get '/privacy-policy'

    assert_redirected_to '/privacy'
  end
end
