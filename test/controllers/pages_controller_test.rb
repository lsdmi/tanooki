# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'should get rules' do
    get rules_url

    assert_response :success
  end

  test 'rules page covers age rating labelling and gating' do
    get rules_url

    assert_select 'h3', text: 'Вікові обмеження'
    assert_select 'li', text: /Твори 16\+ мають бути позначені/
    assert_select 'li', text: /Твори 18\+ мають бути позначені та захищені/
  end

  test 'rules page forbids explicit sex labelled as sixteen' do
    get rules_url

    assert_select 'li', text: /під позначкою 16\+ є порушенням правил/
  end

  test 'should get friends' do
    get friends_url

    assert_response :success
    assert_select 'h1', text: 'Друзі Баки'
  end

  test 'friends page defers the writer background image' do
    get friends_url

    assert_select '[data-controller="lazy-bg"][data-lazy-bg-url-value*="writer"]', count: 1
    assert_select '[style*="writer"]', count: 0
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
