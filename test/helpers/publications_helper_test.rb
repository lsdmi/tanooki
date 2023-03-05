# frozen_string_literal: true

require 'test_helper'

class PublicationsHelperTest < ActionView::TestCase
  include Devise::Test::IntegrationHelpers
  include PublicationsHelper
  include ActionView::TestCase::Behavior

  class PublicationBlogsHelperTest < PublicationsHelperTest
    setup do
      PublicationsHelper.send(:define_method, :blog_controller?) do |*_args|
        true
      end

      PublicationsHelper.send(:define_method, :controller_path) do |*_args|
        'blogs'
      end
    end

    test 'should return correct static variables for blogs' do
      variables = static_variables
      assert_equal '/blogs/new', variables[:new_publication_path]
      assert_equal 'Оновити Допис', variables[:publication_edit_header]
      assert_equal 'Мій Блог', variables[:publication_index_header]
      assert_equal 'Створити Допис', variables[:publication_new_header]
    end

    test 'should return correct dynamic variables for blogs' do
      variables = dynamic_variables('test-slug', Blog)

      assert_equal '/blogs/test-slug/edit', variables[:edit_publication_path]
      assert_equal '/blogs/test-slug', variables[:show_publication_path]
    end
  end

  class PublicationTalesHelperTest < PublicationsHelperTest
    setup do
      PublicationsHelper.send(:define_method, :blog_controller?) do |*_args|
        false
      end

      PublicationsHelper.send(:define_method, :controller_path) do |*_args|
        'admin/tales'
      end
    end

    test 'should return correct static variables for tales' do
      variables = static_variables
      assert_equal '/admin/tales/new', variables[:new_publication_path]
      assert_equal 'Оновити Звістку', variables[:publication_edit_header]
      assert_equal 'Керування Звістками', variables[:publication_index_header]
      assert_equal 'Створити Звістку', variables[:publication_new_header]
    end

    test 'should return correct dynamic variables for tales' do
      variables = dynamic_variables('test-slug', Tale)

      assert_equal '/admin/tales/test-slug/edit', variables[:edit_publication_path]
      assert_equal '/tales/test-slug', variables[:show_publication_path]
    end
  end

  test 'should return correct status variables' do
    variables = status_variables('created')

    assert_equal 'bg-indigo-100 border-indigo-500 text-indigo-900', variables[:class]
    assert_equal 'Модерується', variables[:heading]

    variables = status_variables('approved')

    assert_equal 'bg-teal-100 border-teal-500 text-teal-900', variables[:class]
    assert_equal 'Опубліковано', variables[:heading]

    variables = status_variables('rejected')

    assert_equal 'bg-red-100 border-red-500 text-red-900', variables[:class]
    assert_equal 'Відхилено', variables[:heading]
  end

  test 'should return correct publication index header' do
    PublicationsHelper.send(:define_method, :controller_path) do |*_args|
      'test-path'
    end
    assert_equal 'Керування Звістками', publication_index_header

    PublicationsHelper.send(:define_method, :controller_path) do |*_args|
      'blogs'
    end
    assert_equal 'Мій Блог', publication_index_header

    PublicationsHelper.send(:define_method, :controller_path) do |*_args|
      'admin/blogs'
    end
    assert_equal 'Модерування Блогів', publication_index_header
  end
end
