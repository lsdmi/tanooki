# frozen_string_literal: true

require 'test_helper'

class PublicationsTelegramJobTest < ActiveSupport::TestCase
  test 'perform sends message in production when there are recent publications' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
      api_mock = Minitest::Mock.new
      api_mock.expect(:send_message, nil) do |params|
        assert_equal '@bakaInUa', params[:chat_id]
        assert_equal expected_text_message, params[:text]
        assert_equal 'HTML', params[:parse_mode]
      end

      bot_mock = Minitest::Mock.new
      bot_mock.expect(:api, api_mock)

      TelegramBot.stub(:client, bot_mock) do
        PublicationsTelegramJob.new.perform
      end

      api_mock.verify
      bot_mock.verify
    end
  end

  def expected_text_message
    ActionController::Base.helpers.sanitize(
      "📝 <i><b>Збірка останніх дописів на <a href=\"https://baka.in.ua/tales\">сайті</a></b> \n\n" \
      "#{recent_publications} \n\n" \
      "✨ <b>Підтримайте нас на <a href=\"https://www.buymeacoffee.com/bakainua\">buymeacoffee</a>!</b></i> ✨ \n\n "
    )
  end

  def recent_publications
    Publication.weekly.map do |tale|
      "📰 <b><a href=\"https://baka.in.ua/tales/#{tale.slug}\">#{tale.title}</a></b>"
    end.join("\n\n")
  end
end
