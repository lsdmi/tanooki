# frozen_string_literal: true

require 'test_helper'

class TagTest < ActiveSupport::TestCase
  def setup
    @tag = tags(:three)
  end

  test 'should be valid' do
    assert @tag.valid?
  end

  test 'name should be present' do
    @tag.name = ''
    assert_not @tag.valid?
  end

  test 'name should be unique' do
    duplicate_tag = @tag.dup
    @tag.save
    assert_not duplicate_tag.valid?
  end

  test 'name should not be too long' do
    @tag.name = 'a' * 31
    assert_not @tag.valid?
  end

  test 'publications association should be valid' do
    publication = publications(:tale_approved_one)
    publication.tags << @tag
    assert_includes @tag.publications, publication
  end

  test 'should destroy associated publication_tags' do
    publication = publications(:tale_approved_one)
    publication.tags << @tag
    assert_difference 'PublicationTag.count', -1 do
      @tag.destroy
    end
  end
end
