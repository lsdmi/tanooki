# frozen_string_literal: true

require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  include Devise::Test::IntegrationHelpers

  test 'requires tinymce for admin/tales' do
    request.path = admin_tales_path
    assert requires_tinymce?
  end

  test 'requires tinymce for publications/new' do
    request.path = new_publication_path
    assert requires_tinymce?
  end

  test 'requires tinymce for chapters/new' do
    request.path = new_chapter_path
    assert requires_tinymce?
  end

  test 'requires tinymce for fictions/new' do
    request.path = new_fiction_path
    assert requires_tinymce?
  end

  test 'does not require tinymce for other pages' do
    request.path = root_path
    refute requires_tinymce?
  end

  test 'punch should return string if first sentence if less than 20 characters' do
    string = 'This is a test. This is only a test.'
    assert_equal string, punch(string)
  end

  test 'punch should return the whole string if there is no sentence end' do
    string = 'This is a test'
    assert_equal string, punch(string)
  end

  test 'punch should handle special characters' do
    string = 'This is a test! And this is another test?'
    assert_equal string, punch(string)
  end

  test 'punch should handle empty strings' do
    string = ''
    assert_equal '', punch(string)
  end
end
