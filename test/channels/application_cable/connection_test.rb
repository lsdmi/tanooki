# frozen_string_literal: true

require 'test_helper'

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    def setup
      @user = users(:user_one)
    end

    test 'connection identifies current_user' do
      # Test that the connection can identify a user
      # This is a basic test to ensure the connection class works
      assert ApplicationCable::Connection.identified_by.include?(:current_user)
    end

    test 'connection class has required methods' do
      # Test that the connection class has the required methods
      assert_respond_to ApplicationCable::Connection, :identified_by
      assert ApplicationCable::Connection.instance_methods.include?(:connect)
      assert ApplicationCable::Connection.instance_methods.include?(:current_user)
    end
  end
end
