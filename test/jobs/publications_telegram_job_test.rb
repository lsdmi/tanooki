# frozen_string_literal: true

require 'test_helper'

class PublicationsTelegramJobTest < ActiveSupport::TestCase
  test 'perform sends message in production when there are recent publications' do
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
        PublicationsTelegramJob.new.perform
      end

      api_mock.verify
      bot_mock.verify
    end
  end

  def expected_text_message
    ActionController::Base.helpers.sanitize(
      "📝 <i>Збірка останніх дописів на нашому <b><a href=\"https://baka.in.ua/tales\">сайті</a></b></i> 📝 \n\n" \
      "#{recent_publications} \n\n" \
      "🎉 <i>Підтримуйте нас на <b><a href=\"https://www.buymeacoffee.com/bakainua\">buymeacoffee</a></b>!</i> 🎉 \n\n"
    )
  end

  def recent_publications
    Publication.recent.map do |publication|
      publication_details = "🏷️ <b><a href=\"https://baka.in.ua/tales/#{publication.slug}\">#{publication.title}</a></b> \n\n"
      publication_description = "<i>#{publication.description.to_plain_text[0..120]}...</i> \n\n"
      tag_details = publication.tags.map { |tag| "<i>##{tag.name.downcase.gsub(/[\s,!\-]+/, '_').gsub(/_$/, '')}</i>" }.join(', ')
      "#{publication_details}#{publication_description}#{tag_details}"
    end.join("\n\n")
  end
end
