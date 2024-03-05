# frozen_string_literal: true

require 'test_helper'

class FictionssTelegramJobTest < ActiveSupport::TestCase
  test 'perform sends message in production when there are recent fictions' do
    rails_env_mock = Minitest::Mock.new
    rails_env_mock.expect(:production?, true)

    Rails.stub(:env, rails_env_mock) do
      api_mock = Minitest::Mock.new
      api_mock.expect(:send_message, nil) do |params|
        assert_equal '@bakaInUa', params[:chat_id]
        assert_equal expected_text_message, params[:text]
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

  def expected_text_message
    ActionController::Base.helpers.sanitize(
      "📚 <i>Нові веб-романи на <b><a href=\"https://baka.in.ua/fictions\">Баці</a></b></i> 📚 \n\n" \
      "#{recent_fictions} \n\n" \
      "✨ <i>Підтримайте нас на <b><a href=\"https://www.buymeacoffee.com/bakainua\">buymeacoffee</a></b>!</i> ✨ \n\n "
    )
  end

  def recent_fictions
    Fiction.recent.map do |fiction|
      fiction_details = "📖 <b><a href=\"https://baka.in.ua/fictions/#{fiction.slug}\">#{fiction.title}</a></b> \n\n"
      fiction_description = "<i>#{fiction.description[0..100]}...</i> \n\n"
      genre_details = fiction.genres.map { |genre| "<i>##{genre.name.downcase.gsub(/[\s,!\-]+/, '_').gsub(/_$/, '')}</i>" }.join(', ')
      "#{fiction_details}#{fiction_description}#{genre_details}"
    end.join("\n\n")
  end
end
