# frozen_string_literal: true

require 'test_helper'

class FictionsTelegramJobTest < ActiveSupport::TestCase
  test 'perform sends message in production when there are recent fictions' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
      expected_text = FictionsTelegramJob.new.send(:text_message)

      api_mock = Minitest::Mock.new
      api_mock.expect(:send_message, nil) do |params|
        assert_equal '@bakaInUa', params[:chat_id]
        assert_equal expected_text, params[:text]
        assert_equal 'HTML', params[:parse_mode]
      end

      bot_mock = Minitest::Mock.new
      bot_mock.expect(:api, api_mock)

      TelegramBot.stub(:client, bot_mock) do
        FictionsTelegramJob.new.perform
      end

      api_mock.verify
      bot_mock.verify
    end
  end
end
