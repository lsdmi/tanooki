# frozen_string_literal: true

require 'test_helper'

class PagesApiTest < ActionDispatch::IntegrationTest
  test 'the api docs are public' do
    get api_docs_path

    assert_response :success
    assert_select 'h1', text: 'API для команд'
    assert_select 'a[href="/api/v1/openapi.json"]'
  end

  test 'the docs explain the assistant connection' do
    get api_docs_path

    assert_select 'h2', text: 'Помічник'
    assert_match 'https://baka.in.ua/mcp', response.body
    assert_match 'ChatGPT підключається з цієї ж адреси', response.body
  end

  test 'the docs mention volume_number for chapters' do
    get api_docs_path

    assert_match 'volume_number', response.body
    assert_match '"volume_number":2', response.body
  end

  test 'the docs mention published_at for scheduled release' do
    get api_docs_path

    assert_match 'published_at', response.body
    assert_match 'ISO 8601', response.body
  end

  test 'the docs separate chapter catalog from bodies' do
    get api_docs_path

    assert_match 'Каталог і текст розділені', response.body
    assert_match 'body=all|html|paragraphs', response.body
    assert_match 'chapters/batch', response.body
  end
end
