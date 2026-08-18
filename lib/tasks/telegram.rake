# frozen_string_literal: true

namespace :telegram do
  desc 'Post a weekly Telegram digest (DIGEST=...; optional TELEGRAM_CHAT_ID=@bakaTgTest)'
  task digest: :environment do
    digest = ENV.fetch('DIGEST')
    TelegramDigests::Post.call(digest)
    puts "digest=#{digest} chat=#{TelegramDigests::Sender.chat_id} posted"
  rescue ArgumentError => e
    abort e.message
  end
end
