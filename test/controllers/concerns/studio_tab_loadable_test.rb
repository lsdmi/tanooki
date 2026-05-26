# frozen_string_literal: true

require 'test_helper'
require_relative 'studio_tab_loadable_test_support'

class StudioTabLoadableTest < ActiveSupport::TestCase
  include StudioTabLoadableStubHelpers

  setup do
    @user = users(:user_one)
    @harness = StudioTabLoadableHarness.new(@user)
  end

  test 'default_tab returns blogs' do
    assert_equal 'blogs', @harness.send(:default_tab)
  end

  test 'assign_instance_variables sets empty arrays for missing collections' do
    @harness.instance_variable_set(:@comments, nil)
    @harness.instance_variable_set(:@fictions, nil)
    @harness.send(:assign_instance_variables)

    expected = {
      comments: [], fictions: [], publications: [], avatars: [], scanlators: [], bookshelves: [],
      epub_export_requests: []
    }
    actual = {
      comments: @harness.instance_variable_get(:@comments),
      fictions: @harness.instance_variable_get(:@fictions),
      publications: @harness.instance_variable_get(:@publications),
      avatars: @harness.instance_variable_get(:@avatars),
      scanlators: @harness.instance_variable_get(:@scanlators),
      bookshelves: @harness.instance_variable_get(:@bookshelves),
      epub_export_requests: @harness.instance_variable_get(:@epub_export_requests)
    }

    assert_equal expected, actual
  end

  test 'assign_instance_variables_from_service copies pagy pokemon_show and fictions from service' do
    service = stub_tab_content_service(
      pagy: :stub_pagy, pokemon_show: :stub_pokemon, fictions: [1]
    )
    @harness.send(:assign_instance_variables_from_service, service)

    assert_equal :stub_pagy, @harness.instance_variable_get(:@pagy)
    assert_equal :stub_pokemon, @harness.instance_variable_get(:@pokemon_show)
    assert_equal [1], @harness.instance_variable_get(:@fictions)
  end

  test 'assign_instance_variables_from_service normalizes nil collection ivars to empty arrays' do
    service = stub_tab_content_service
    @harness.send(:assign_instance_variables_from_service, service)

    expected = {
      publications: [], scanlators: [], fictions: [], comments: [], avatars: [], bookshelves: [],
      epub_export_requests: []
    }
    actual = {
      publications: @harness.instance_variable_get(:@publications),
      scanlators: @harness.instance_variable_get(:@scanlators),
      fictions: @harness.instance_variable_get(:@fictions),
      comments: @harness.instance_variable_get(:@comments),
      avatars: @harness.instance_variable_get(:@avatars),
      bookshelves: @harness.instance_variable_get(:@bookshelves),
      epub_export_requests: @harness.instance_variable_get(:@epub_export_requests)
    }

    assert_equal expected, actual
  end

  test 'load_tab_content delegates to TabContent and assigns instance variables' do
    @harness.instance_variable_set(:@active_tab, 'blogs')
    @harness.params = ActionController::Parameters.new(page: 1)
    @harness.send(:load_tab_content)

    assert_instance_of Pagy, @harness.instance_variable_get(:@pagy)
    assert_equal @user.publications.order(created_at: :desc).limit(8).to_a,
                 @harness.instance_variable_get(:@publications).to_a
  end
end
