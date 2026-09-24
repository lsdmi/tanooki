# frozen_string_literal: true

require 'test_helper'

module TelegramDigests
  class FictionsTest < ActiveSupport::TestCase
    setup do
      @run_at = Time.zone.parse('2026-09-17 14:00')
      @created_at = Time.zone.parse('2026-09-12 12:00')
      @everyone = fictions(:one)
      @sixteen = fictions(:two)
      @eighteen = fictions(:eighteen)
      @eighteen.scanlators << scanlators(:one) unless @eighteen.scanlators.exists?(scanlators(:one).id)
    end

    test 'call sends message in production when there are thursday digest fictions' do
      travel_to @run_at do
        @everyone.update!(created_at: @created_at)

        Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
          expected_text = Fictions.new.text_message
          sent = capture_send { Fictions.call }

          assert_equal(
            { chat_id: '@bakaInUa', text: expected_text, parse_mode: 'HTML' },
            sent
          )
        end
      end
    end

    test 'text_message keeps eighteen works in the digest' do
      travel_to @run_at do
        stamp_digest_window(@everyone, @sixteen, @eighteen)

        text = Fictions.new.text_message

        assert_includes text, @everyone.title
        assert_includes text, @eighteen.title
      end
    end

    test 'text_message appends sixteen and eighteen hashtags' do
      travel_to @run_at do
        stamp_digest_window(@sixteen, @eighteen)

        text = Fictions.new.text_message

        assert_includes text, '#16+'
        assert_includes text, '#18+'
      end
    end

    test 'text_message omits a rating hashtag for everyone' do
      travel_to @run_at do
        Fiction.where.not(id: @everyone.id).find_each do |fiction|
          fiction.update!(created_at: 1.month.ago)
        end
        @everyone.update!(created_at: @created_at, content_rating: :everyone)

        text = Fictions.new.text_message

        assert_includes text, @everyone.title
        assert_not_includes text, '#16+'
        assert_not_includes text, '#18+'
      end
    end

    private

    def stamp_digest_window(*fictions)
      fictions.each { |fiction| fiction.update!(created_at: @created_at) }
    end

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
  end
end
