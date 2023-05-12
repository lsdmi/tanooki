# frozen_string_literal: true

require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  include Devise::Test::IntegrationHelpers

  test 'should get meta_title for root path' do
    request.path = root_path
    assert_equal 'Бака - Новини Аніме та Манґа', meta_title
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
    description = 'Бака - провідний портал аніме та манґа новин в Україні: новини, огляди, статті, інтерв\'ю та інше.'

    request.path = root_path
    assert_equal description, meta_description
  end

  test 'should get meta_description for publication path' do
    @publication = publications(:tale_approved_one)
    assert_equal  @publication.description.to_plain_text.split(/(?<=[.?!])\s+/).first, meta_description
  end

  test 'should get meta_description for search path' do
    description = 'Бака - провідний портал аніме та манґа новин в Україні: новини, огляди, статті, інтерв\'ю та інше.'

    request.path = search_index_path
    assert_equal description, meta_description
  end

  test 'requires tinymce for admin/tales' do
    request.path = admin_tales_path
    assert requires_tinymce?
  end

  test 'requires tinymce for dashboard' do
    request.path = dashboard_path
    assert requires_tinymce?
  end

  test 'requires tinymce for publications/new' do
    request.path = new_publication_path
    assert requires_tinymce?
  end

  test 'requires tinymce for chapters/new' do
    request.path = new_admin_chapter_path
    assert requires_tinymce?
  end

  test 'requires tinymce for fictions/new' do
    request.path = new_admin_fiction_path
    assert requires_tinymce?
  end

  test 'does not require tinymce for other pages' do
    request.path = root_path
    refute requires_tinymce?
  end

  test 'meta_image returns expected URL for home controller' do
    @highlights = [Struct.new(:cover).new('highlights_cover.jpg')]
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
    assert_equal asset_path('login.jpg'), meta_image
  end

  test 'meta_image returns expected URL for other controllers with publication' do
    @publication = publications(:tale_approved_one)
    assert_equal url_for(@publication.cover), meta_image
  end

  test 'meta_image returns fallback URL when no results or publication covers are available' do
    request.path = search_index_path
    @results = []
    @publication = nil
    assert_equal asset_path('login.jpg'), meta_image
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

  test 'punch should return the first sentence of a string' do
    string = 'This is a test. This is only a test.'
    assert_equal 'This is a test.', punch(string)
  end

  test 'punch should return the whole string if there is no sentence end' do
    string = 'This is a test'
    assert_equal string, punch(string)
  end

  test 'punch should handle special characters' do
    string = 'This is a test! And this is another test?'
    assert_equal 'This is a test!', punch(string)
  end

  test 'punch should handle empty strings' do
    string = ''
    assert_equal '', punch(string)
  end
end
