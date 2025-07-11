# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :output, './log/cron.log'
set :path, '/home/deploy/tanooki/current'

set :bundle_command, '/home/deploy/.rbenv/shims/bundler exec'
job_type :runner, "cd :path && :bundle_command rails runner -e :environment ':task' :output"

case @environment
when 'production'
  every 12.hours do
    runner 'YoutubeChannel.all.each { |channel| Youtube::VideosJob.perform_now(channel.channel_id) }'
  end

  every 3.days, at: '2pm' do
    runner 'FictionsTelegramJob.perform_now'
  end

  every 5.days, at: '3pm' do
    runner 'PublicationsTelegramJob.perform_now'
  end

  every :sunday, at: '12pm' do
    runner 'Fiction.all.each { |fiction| fiction.set_dropped_status unless fiction.finished? }'
    runner 'Youtube::TelegramJob.perform_now'
  end
end
