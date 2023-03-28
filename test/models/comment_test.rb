# frozen_string_literal: true

require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  setup do
    @publication = publications(:tale_approved_one)
    @user = users(:user_one)
  end

  test 'should be invalid without content' do
    comment = Comment.new(content: nil)
    assert_not comment.valid?, 'Comment is valid without content'
  end

  test 'should be invalid with content that is too long' do
    content = 'a' * 2201
    comment = Comment.new(content:)
    assert_not comment.valid?, 'Comment is valid with content that is too long'
  end

  test 'should be valid with required attributes' do
    comment = Comment.new(content: 'valid comment', publication: @publication, user: @user)
    assert comment.valid?, 'Comment is invalid with required attributes'
  end

  test 'should destroy child comments when parent is destroyed' do
    parent = Comment.create(content: 'Parent comment', publication: @publication, user: @user)
    child1 = Comment.create(content: 'Child 1', parent:, publication: @publication, user: @user)
    child2 = Comment.create(content: 'Child 2', parent:, publication: @publication, user: @user)

    parent.destroy

    assert_not Comment.exists?(parent.id)
    assert_not Comment.exists?(child1.id)
    assert_not Comment.exists?(child2.id)
  end

  test 'should return only parent comments in parents scope' do
    parent1 = Comment.create(content: 'Parent 1', publication: @publication, user: @user)
    child1 = Comment.create(content: 'Child 1', parent: parent1, publication: @publication, user: @user)
    child2 = Comment.create(content: 'Child 2', parent: parent1, publication: @publication, user: @user)

    parent2 = Comment.create(content: 'Parent 2', publication: @publication, user: @user)
    parents = Comment.parents

    assert_includes parents, parent1
    assert_not_includes parents, child1
    assert_not_includes parents, child2
    assert_includes parents, parent2
  end
end
