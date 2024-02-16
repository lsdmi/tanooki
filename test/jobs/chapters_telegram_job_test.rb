# frozen_string_literal: true

require 'test_helper'

class ChaptersTelegramJobTest < ActiveSupport::TestCase
  test 'perform sends message in production when there are recent chapters' do
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
        ChaptersTelegramJob.new.perform
      end

      api_mock.verify
      bot_mock.verify
    end
  end

  def expected_text_message
    ActionController::Base.helpers.sanitize(
      "🚀 <i>Нові релізи вже на <b><a href=\"https://baka.in.ua/fictions\">сайті</a></b></i> 🚀\n\n" \
      "#{Fiction.recent_chapters.map { |fiction| expected_recent_chapters(fiction) }.join("\n\n") }\n\n" \
      '💫 <i>Хутчіш ознайомлюйтеся та не забувайте підтримувати на ' \
      "<b><a href=\"https://www.buymeacoffee.com/bakainua\">buymeacoffee</a></b>!</i> 💫 \n\n "
    )
  end

  def expected_recent_chapters(fiction)
    "🔔 <b><a href=\"https://baka.in.ua/fictions/#{fiction.slug}\">#{fiction.title}</a></b>\n\n" \
    "#{fiction.chapters.recent.order(created_at: :desc).map do |chapter|
      "📖 <i>#{chapter.display_title}</i>\n"
    end.join}\n" \
    "#{fiction.genres.map { |genre| "<i>##{genre.name.downcase.gsub(/[\s,!\-]+/, '_').gsub(/_$/, '')}</i>" }.join(', ')}"
  end
end
