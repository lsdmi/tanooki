# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.new(
      name: 'John Three',
      email: 'john@example.com',
      password: 'password',
      password_confirmation: 'password',
      avatar_id: avatars(:one).id
    )
  end

  test 'should be valid' do
    assert @user.valid?
  end

  test 'name should not be too short' do
    @user.name = 'a' * 2
    assert_not @user.valid?
  end

  test 'name should not be too long' do
    @user.name = 'a' * 21
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

  test 'should belong to an avatar' do
    assert_equal avatars(:one), @user.avatar
  end

  test 'creates a new user if user with email does not exist' do
    access_token = OmniAuth::AuthHash.new(
      {
        provider: 'google',
        uid: '123456',
        info: { email: 'test@example.com', name: 'Test User' },
        credentials: { token: 'token', refresh_token: 'refresh_token', expires_at: Time.now + 1.day }
      }
    )

    assert_difference 'User.count', 1 do
      User.from_omniauth(access_token)
    end

    assert_equal User.last.email, 'test@example.com'
    assert_equal User.last.name, 'Test User'
  end

  test 'returns existing user if user with email already exists' do
    user = users(:user_one)
    access_token = OmniAuth::AuthHash.new(
      {
        provider: 'google',
        uid: '123456',
        info: { email: user.email, name: user.name },
        credentials: { token: 'token', refresh_token: 'refresh_token', expires_at: Time.now + 1.day }
      }
    )

    assert_no_difference 'User.count' do
      assert_equal user, User.from_omniauth(access_token)
    end
  end

  test 'truncates name to 20 characters' do
    access_token = OmniAuth::AuthHash.new(
      {
        provider: 'google',
        uid: '123456',
        info: { email: 'test@example.com', name: 'Test User Test User Test User Test User Test User' },
        credentials: { token: 'token', refresh_token: 'refresh_token', expires_at: Time.now + 1.day }
      }
    )

    assert_difference 'User.count', 1 do
      User.from_omniauth(access_token)
    end

    assert_equal User.last.name, 'Test User Test User '
  end
end
