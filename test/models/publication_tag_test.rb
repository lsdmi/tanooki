# frozen_string_literal: true

require 'test_helper'

class PublicationTagTest < ActiveSupport::TestCase
  def setup
    @publication = publications(:tale_approved_one)
    @tag = tags(:one)
    @publication_tag = publication_tags(:one)
  end

  test 'should be valid' do
    assert @publication_tag.valid?
  end

  test 'should require publication' do
    @publication_tag.publication = nil
    assert_not @publication_tag.valid?
  end

  test 'should require tag' do
    @publication_tag.tag = nil
    assert_not @publication_tag.valid?
  end

  test 'should belong to publication' do
    assert_equal @publication, @publication_tag.publication
  end

  test 'should belong to tag' do
    assert_equal @tag, @publication_tag.tag
  end
end
