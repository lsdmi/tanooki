# frozen_string_literal: true

require 'test_helper'

class PublicationTest < ActiveSupport::TestCase
  setup do
    @publication = publications(:tale_approved_one)
    @publication_created = publications(:tale_created_one)
    @user = users(:user_one)
  end

  test 'should belong to user' do
    assert_equal @user, @publication.user
  end

  test 'should have one attached cover' do
    assert @publication.cover.attached?
  end

  test 'should have rich text description' do
    assert @publication.description.present?
  end

  test 'should be invalid without title' do
    @publication.title = nil
    assert_not @publication.valid?
  end

  test 'should be invalid without description' do
    @publication.description = nil
    assert_not @publication.valid?
  end

  test 'should be invalid without cover' do
    @publication.cover = nil
    assert_not @publication.valid?
  end

  test 'should be invalid without status' do
    @publication.status = nil
    assert_not @publication.valid?
  end

  test 'should be invalid without status message' do
    @publication.status_message = nil
    assert_not @publication.valid?
  end

  test 'should have highlights scope' do
    assert_includes Publication.highlights, @publication
  end

  test 'should have last_month scope' do
    assert_includes Publication.last_month, @publication
  end

  test 'should have created, approved and declined statuses' do
    assert_equal 3, Publication.statuses.count
    assert_equal 'created', Publication.statuses[:created]
    assert_equal 'approved', Publication.statuses[:approved]
    assert_equal 'declined', Publication.statuses[:declined]
  end

  test 'should return true for should_index? when approved' do
    assert @publication.should_index?
  end

  test 'should return false for should_index? when not approved' do
    assert_not @publication_created.should_index?
  end

  test 'should have many publication tags' do
    assert_instance_of PublicationTag, @publication.publication_tags.build
  end

  test 'should have many tags through publication tags' do
    assert_instance_of Tag, @publication.tags.build
  end

  test 'should destroy associated publication tags when destroyed' do
    assert_difference 'PublicationTag.count', -1 do
      @publication.destroy
    end
  end
end
