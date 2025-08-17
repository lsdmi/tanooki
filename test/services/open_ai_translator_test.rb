# frozen_string_literal: true

require 'test_helper'

class OpenAiTranslatorTest < ActiveSupport::TestCase
  def setup
    @translator = OpenAiTranslator.new
    @article_text = 'This is a test article.'
    @title = 'Test Article'
    @tags = [{ id: 1, name: 'Technology' }]
  end

  test 'initializes successfully' do
    assert_instance_of OpenAiTranslator, @translator
  end

  test 'includes ContentTranslatorInterface' do
    assert @translator.respond_to?(:translate)
  end

  test 'translation_prompt includes required elements' do
    prompt = @translator.send(:translation_prompt, @article_text, @title, @tags)

    assert_includes prompt, 'Переклади статтю українською мовою'
    assert_includes prompt, @title
    assert_includes prompt, @article_text
    assert_includes prompt, @tags.to_json
  end

  test 'api_parameters returns correct structure' do
    prompt = @translator.send(:translation_prompt, @article_text, @title, @tags)
    params = @translator.send(:api_parameters, prompt)

    assert_equal 'gpt-4.1', params[:model]
    assert_equal 0.5, params[:temperature]
    assert_equal 2, params[:messages].length
    assert_equal 'system', params[:messages][0][:role]
    assert_equal 'user', params[:messages][1][:role]
  end

  test 'parse_translation_response extracts tag_ids correctly' do
    content_with_tags = 'Translated HTML content [1, 3]'
    result = @translator.send(:parse_translation_response, content_with_tags)

    assert_equal [1, 3], result.tag_ids
    assert_equal 'Translated HTML content', result.html.strip
  end

  test 'parse_translation_response handles no tags' do
    content_without_tags = 'Translated HTML content without tags'
    result = @translator.send(:parse_translation_response, content_without_tags)

    assert_equal [], result.tag_ids
    assert_equal 'Translated HTML content without tags', result.html.strip
  end

  test 'translate returns nil when API response is blank' do
    @translator.stub :call_openai_api, nil do
      result = @translator.translate(@article_text, @title, @tags)
      assert_nil result
    end
  end

  test 'translate returns nil when API call raises error' do
    @translator.stub :call_openai_api, ->(*) { raise StandardError, 'API Error' } do
      result = @translator.translate(@article_text, @title, @tags)
      assert_nil result
    end
  end
end
