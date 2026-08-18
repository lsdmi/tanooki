# frozen_string_literal: true

require 'test_helper'

module TelegramDigests
  class PublicationsTest < ActiveSupport::TestCase
    test 'call sends message in production when there are recent publications' do
      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        sent = capture_send { Publications.call }

        assert_equal(
          { chat_id: '@bakaInUa', text: expected_text_message, parse_mode: 'HTML' },
          sent
        )
      end
    end

    private

    def capture_send(&)
      slot = []
      api = Minitest::Mock.new
      api.expect(:send_message, nil) { |params| slot[0] = params }
      bot = Minitest::Mock.new
      bot.expect(:api, api)
      TelegramBot.stub(:client, bot, &)
      api.verify && bot.verify
      slot[0]
    end

    def expected_text_message
      ActionController::Base.helpers.sanitize(
        "📝 <i><b>Збірка останніх дописів на <a href=\"https://baka.in.ua/tales\">сайті</a></b> \n\n" \
        "#{recent_publications} \n\n" \
        "✨ <b>Підтримайте нас на <a href=\"https://www.buymeacoffee.com/bakainua\">buymeacoffee</a>!</b></i> ✨ \n\n "
      )
    end

    def recent_publications
      Publication.weekly.limit(Publications::WEEKLY_PUBLICATIONS_LIMIT).map do |tale|
        "📰 <b><a href=\"https://baka.in.ua/tales/#{tale.slug}\">#{tale.title}</a></b>"
      end.join("\n\n")
    end
  end
end
