# frozen_string_literal: true

require 'test_helper'

class AssetsPipelineTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'propshaft is the asset pipeline' do
    assert defined?(Propshaft::Railtie)
    assert_not defined?(Sprockets::Rails)
  end

  test 'tinymce uses copy install mode for undigested runtime assets' do
    assert_equal :copy, Rails.application.config.tinymce.install
  end

  test 'publication form loads tinymce library instead of sprockets bundle stub' do
    user = users(:user_one)
    sign_in user

    get new_publication_url

    assert_response :success
    assert_includes response.body, 'tinymce/tinymce'
    assert_not_includes response.body, '//= require tinymce/tinymce.js'
  end

  test 'tinymce preinit script is valid javascript' do
    user = users(:user_one)
    sign_in user

    get new_publication_url

    preinit = response.body[/window\.tinymce = window\.tinymce \|\| \{.*?\};/m]

    assert_includes preinit, 'base: "/assets/tinymce"'
    assert_not_includes preinit, '&#39;'
  end

  test 'chapter edit form loads tinymce initializer' do
    sign_in users(:user_one)

    get edit_chapter_url(chapters(:one))

    assert_response :success
    assert_includes response.body, 'tinymce_initializer'
  end

  test 'tinymce initializer syncs editor content before turbo submit' do
    source = Rails.root.join('app/javascript/tinymce_initializer.js').read

    assert_includes source, 'turbo:submit-start'
    assert_includes source, 'editor.save()'
  end
end
