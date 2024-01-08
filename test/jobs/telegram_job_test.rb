# frozen_string_literal: true

require 'test_helper'

class TelegramJobTest < ActiveSupport::TestCase
  test 'perform sends message in production' do
    rails_env_mock = Minitest::Mock.new
    rails_env_mock.expect(:production?, true)

    Rails.stub(:env, rails_env_mock) do
      object = mock_telegram_object

      bot_mock = Minitest::Mock.new
      api_mock = Minitest::Mock.new

      api_mock.expect(:send_message, nil) do |params|
        assert_equal '@bakaInUa', params[:chat_id]
        assert_equal object.telegram_message, params[:text]
        assert_equal 'HTML', params[:parse_mode]
      end

      bot_mock.expect(:api, api_mock)

      TelegramBot.stub(:client, bot_mock) do
        TelegramJob.new.perform(object:)
      end

      api_mock.verify
      bot_mock.verify
    end
  end

  def mock_telegram_object
    mock_object = Minitest::Mock.new
    mock_object.expect(:telegram_message, 'Test message')
    mock_object.expect(:telegram_message, 'Test message')
    mock_object
  end
end
