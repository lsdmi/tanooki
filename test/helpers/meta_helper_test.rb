# frozen_string_literal: true

require 'test_helper'

class MetaHelperTest < ActionView::TestCase
  include ApplicationHelper
  include MetaCoverHelper
  include MetaDescriptionHelper
  include Devise::Test::IntegrationHelpers

  test 'should get meta_title for root path' do
    request.path = root_path
    assert_equal 'Бака: про аніме українською', meta_title
  end

  test 'should get meta_title for search path' do
    request.path = search_index_path
    controller.params[:search] = ['test']
    assert_equal 'test | Бака', meta_title
  end

  test 'should get meta_title for publication path' do
    @publication = publications(:tale_approved_one)
    assert_equal @publication.title, meta_title
  end

  test 'should get meta_description for root path' do
    description = 'Бака - винятковий портал, де зібрані усі новини, блоги, відео по аніме, манзі, культурі Сходу, ' \
                  'а також перекладається ранобе українською мовою.'

    request.path = root_path
    assert_equal description, meta_description
  end

  test 'should get meta_description for publication path' do
    @publication = publications(:tale_approved_one)
    assert_equal  @publication.description.to_plain_text.split(/(?<=[.?!])\s+/).first, meta_description
  end

  test 'should get meta_description for search path' do
    description = 'Бака - винятковий портал, де зібрані усі новини, блоги, відео по аніме, манзі, культурі Сходу, ' \
                  'а також перекладається ранобе українською мовою.'

    request.path = search_index_path
    assert_equal description, meta_description
  end

  test 'meta_image returns expected URL for home controller' do
    @highlights = [Struct.new(:cover).new('/psyduck_background.webp')]
    request.path = root_path
    assert_equal url_for(@highlights.first.cover), meta_image
  end

  test 'meta_image returns expected URL for search controller with results' do
    @results = [Struct.new(:cover).new('results_cover.jpg')]
    request.path = search_index_path
    assert_equal url_for(@results.first.cover), meta_image
  end

  test 'meta_image returns expected URL for search controller without results' do
    @results = []
    request.path = search_index_path
    assert_equal asset_path('/psyduck_background.webp'), meta_image
  end

  test 'meta_image returns expected URL for other controllers with publication' do
    @publication = publications(:tale_approved_one)
    assert_equal url_for(@publication.cover), meta_image
  end

  test 'meta_image returns fallback URL when no results or publication covers are available' do
    request.path = search_index_path
    @results = []
    @publication = nil
    assert_equal asset_path('/psyduck_background.webp'), meta_image
  end

  test 'meta_type returns website for root and search pages' do
    request.path = root_path
    assert_equal 'website', meta_type

    request.path = search_index_path
    assert_equal 'website', meta_type
  end

  test 'meta_type returns article for all other pages' do
    request.path = '/about'
    assert_equal 'article', meta_type
  end
end
