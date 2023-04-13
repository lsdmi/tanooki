# frozen_string_literal: true

require 'test_helper'

class AvatarTest < ActiveSupport::TestCase
  def setup
    @avatar = avatars(:one)
  end

  test 'should be valid' do
    assert @avatar.valid?
  end

  test 'should not be valid without image' do
    @avatar.image.purge
    assert_not @avatar.valid?
    assert_equal ['не може бути пустим'], @avatar.errors[:image]
  end

  test 'should be associated with users' do
    user = users(:user_one)
    user.avatar = @avatar
    user.save
    assert_equal user.avatar, @avatar
    assert_includes @avatar.users, user
  end

  test 'should allow valid image formats' do
    valid_image = Rack::Test::UploadedFile.new(
      Rails.root.join('app', 'assets', 'images', 'logo.svg'),
      'image/svg'
    )

    @avatar.image.attach(valid_image)
    assert @avatar.valid?, 'Allowed valid image format'
  end

  test 'should not allow invalid image format' do
    invalid_image = Rack::Test::UploadedFile.new(
      Rails.root.join('app', 'assets', 'stylesheets', 'actiontext.css')
    )

    @avatar.image.attach(invalid_image)
    refute @avatar.valid?, 'Did not reject invalid image format'
    assert_equal ['Image має бути JPEG, PNG, GIF, SVG, або WebP'], @avatar.errors.full_messages
  end

  test 'reassign_avatars should update avatar for users without avatars' do
    user = users(:user_one)
    user.avatar.destroy
    user.reload.avatar
    assert_equal avatars(:two), user.avatar
  end
end
