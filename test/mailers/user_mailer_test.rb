# frozen_string_literal: true

require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  DeviseMapping = Struct.new(:name)
  Resource = Struct.new(:email)

  test 'headers_for sets the correct template path' do
    devise_mapping = DeviseMapping.new(SecureRandom.hex)
    resource = Resource.new(SecureRandom.hex)

    user_mailer = UserMailer.new
    user_mailer.instance_variable_set(:@devise_mapping, devise_mapping)
    user_mailer.instance_variable_set(:@resource, resource)

    mail = user_mailer.headers_for(:action_name, {})
    assert_equal 'users/mailer', mail[:template_path]
  end
end
