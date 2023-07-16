# frozen_string_literal: true

require 'test_helper'

class TaleTest < ActiveSupport::TestCase
  setup do
    @tale = publications(:tale_approved_one)
  end

  test 'default scope should only return tales' do
    publications = Publication.all
    assert_not_nil publications
    assert_equal 7, publications.length

    tales = Tale.all
    assert_not_nil tales
    assert_equal 7, tales.length
    assert_equal @tale, tales.first
  end
end
