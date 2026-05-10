# frozen_string_literal: true

require 'test_helper'

class TelegramJobTest < ActiveSupport::TestCase
  test 'perform sends video message in production' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
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
        Youtube::TelegramJob.new.perform
      end

      api_mock.verify
      bot_mock.verify
    end
  end

  def mock_telegram_object
    mock_object = Minitest::Mock.new
    mock_object.expect(:telegram_message, expected_message)
    mock_object.expect(:telegram_message, expected_message)
    mock_object
  end

  def expected_message
    ActionController::Base.helpers.sanitize(
      "🌟 <i>Найпопулярніші відео тижня на <b><a href=\"https://baka.in.ua/watch\">Баці</a></b></i> 🌟 \n\n" \
      "🥇 <b><a href=\"https://baka.in.ua/watch/one\">#{YoutubeVideo.first.title}</a></b> 🥇 \n\n" \
      "🎬 <i>Насолоджуйтеся світом японської анімації на нашому сайті!</i> 🎬 \n\n " \
      '<i><b>#щотижневий_ютуб</b></i>'
    )
  end
end
