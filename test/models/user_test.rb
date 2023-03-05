# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.new(
      name: 'John Doe',
      email: 'john@example.com',
      password: 'password',
      password_confirmation: 'password'
    )
  end

  test 'should be valid' do
    assert @user.valid?
  end

  test 'name should be present' do
    @user.name = '     '
    assert_not @user.valid?
  end

  test 'name should not be too short' do
    @user.name = 'a' * 2
    assert_not @user.valid?
  end

  test 'name should not be too long' do
    @user.name = 'a' * 21
    assert_not @user.valid?
  end

  test 'name should only contain letters, numbers, and spaces' do
    valid_names = ['John Doe', 'Jane123', 'Joe B Bloggs']
    valid_names.each do |name|
      @user.name = name
      assert @user.valid?
    end

    invalid_names = ['JohnDoe!', 'Jane@123', 'Joe/B/Bloggs']
    invalid_names.each do |name|
      @user.name = name
      assert_not @user.valid?
    end
  end

  test 'email should be present' do
    @user.email = '    '
    assert_not @user.valid?
  end

  test 'email should be valid' do
    valid_emails = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org first.last@foo.jp alice+bob@baz.cn]
    valid_emails.each do |email|
      @user.email = email
      assert @user.valid?
    end

    invalid_emails = %w[user@example,com user_at_foo.org user.name@example. foo@bar_baz.com foo@bar+baz.com]
    invalid_emails.each do |email|
      @user.email = email
      assert_not @user.valid?
    end
  end

  test 'email should be unique' do
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    @user.save
    assert_not duplicate_user.valid?
  end

  test 'password should be present' do
    @user.password = @user.password_confirmation = ' ' * 6
    assert_not @user.valid?
  end

  test 'password should have a minimum length' do
    @user.password = @user.password_confirmation = 'a' * 5
    assert_not @user.valid?
  end

  test 'should have many blogs' do
    assert_respond_to @user, :blogs
  end

  test 'should have many comments' do
    assert_respond_to @user, :comments
  end

  test 'should have many publications' do
    assert_respond_to @user, :publications
  end
end
