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

  test 'should have highlights scope' do
    assert_includes Publication.highlights, @publication
  end

  test 'should have last_month scope' do
    assert_includes Publication.last_month, @publication
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

  test 'should not save publication with a description shorter than 500 characters' do
    @publication.description = 'Short description'
    assert_not @publication.valid?
  end

  test 'should not save publication with a title shorter than 10 characters' do
    @publication.title = 'Title'
    assert_not @publication.valid?
  end

  test 'should not save publication with a title longer than 100 characters' do
    @publication.title = 'Title' * 25
    assert_not @publication.valid?
  end

  test 'should not save publication with a cover that is not a JPEG, PNG, SVG, or WebP' do
    invalid_image = Rack::Test::UploadedFile.new(
      Rails.root.join('app', 'assets', 'stylesheets', 'actiontext.css')
    )

    @publication.cover.attach(invalid_image)
    assert_not @publication.valid?
  end
end
