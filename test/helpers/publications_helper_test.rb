# frozen_string_literal: true

require 'test_helper'

class PublicationsHelperTest < ActionView::TestCase
  include Devise::Test::IntegrationHelpers
  include PublicationsHelper
  include ActionView::TestCase::Behavior

  class PublicationTalesHelperTest < PublicationsHelperTest
    setup do
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
      variables = dynamic_variables('test-slug')

      assert_equal '/admin/tales/test-slug/edit', variables[:edit_publication_path]
      assert_equal '/tales/test-slug', variables[:show_publication_path]
    end
  end
end
