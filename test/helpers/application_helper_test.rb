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
    assert_equal @publication.description.to_plain_text.truncate(125), meta_description
  end

  test 'should get meta_description for search path' do
    description = 'Бака - провідний портал аніме та манґа новин в Україні: новини, огляди, статті, інтерв\'ю та інше.'

    request.path = search_index_path
    assert_equal description, meta_description
  end
end
