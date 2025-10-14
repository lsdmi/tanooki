# frozen_string_literal: true

require 'dotenv'
Dotenv.load('.env')

# config valid for current version and patch releases of Capistrano
lock '~> 3.19.0'

set :application, 'tanooki'
set :repo_url, 'git@github.com:lsdmi/tanooki.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, 'main'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/deploy/#{fetch :application}"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, '.env'

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', '.bundle', 'public/system',
       'public/uploads'

# Default value for default_env is {}
set :default_env, {
  'DB_HOST' => ENV.fetch('DB_HOST'),
  'DB_NAME' => ENV.fetch('DB_NAME'),
  'DB_PASSWORD' => ENV.fetch('DB_PASSWORD'),
  'DB_PORT' => ENV.fetch('DB_PORT'),
  'DB_USER' => ENV.fetch('DB_USER'),
  'DEPLOY_PRODUCTION_IP' => ENV.fetch('DEPLOY_PRODUCTION_IP'),
  'DEPLOY_PRODUCTION_USER' => ENV.fetch('DEPLOY_PRODUCTION_USER'),
  'ELASTICSEARCH_PASSWORD' => ENV.fetch('ELASTICSEARCH_PASSWORD'),
  'ELASTICSEARCH_USER' => ENV.fetch('ELASTICSEARCH_USER'),
  'GOOGLE_CLIENT_ID' => ENV.fetch('GOOGLE_CLIENT_ID'),
  'GOOGLE_CLIENT_SECRET' => ENV.fetch('GOOGLE_CLIENT_SECRET'),
  'MAILER_PASSWORD' => ENV.fetch('MAILER_PASSWORD'),
  'SECRET_KEY_BASE' => ENV.fetch('SECRET_KEY_BASE'),
  'STORAGE_ACCESS_KEY' => ENV.fetch('STORAGE_ACCESS_KEY'),
  'STORAGE_BUCKET' => ENV.fetch('STORAGE_BUCKET'),
  'STORAGE_ENDPOINT' => ENV.fetch('STORAGE_ENDPOINT'),
  'STORAGE_REGION' => ENV.fetch('STORAGE_REGION'),
  'STORAGE_SECRET_KEY' => ENV.fetch('STORAGE_SECRET_KEY'),
  'TELEGRAM_KEY' => ENV.fetch('TELEGRAM_KEY'),
  'YOUTUBE_API_KEY' => ENV.fetch('YOUTUBE_API_KEY')
}

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
