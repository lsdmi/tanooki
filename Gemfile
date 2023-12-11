# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 7.1.2'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

gem 'mysql2'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 6.1'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem 'image_processing', '~> 1.2'

group :development, :test do
  gem 'debug'
end

group :development do
  gem 'bullet'
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'letter_opener'
  gem 'rails_best_practices'
  gem 'rubocop'
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'faker'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  gem 'simplecov'
  gem 'webdrivers'
end

group :production do
  gem 'aws-sdk-s3'
end

gem 'bcrypt_pbkdf'
gem 'devise'
gem 'dotenv-rails'
gem 'ed25519'
gem 'elasticsearch', '~> 7.17.0'
gem 'faraday-httpclient'
gem 'friendly_id'
gem 'google-apis-youtube_v3'
gem 'i18n'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'
gem 'pagy'
gem 'paranoia'
gem 'rails-i18n'
gem 'searchkick'
gem 'simple_form'
gem 'streamio-ffmpeg'
gem 'tailwindcss-rails'
gem 'telegram-bot-ruby'
gem 'tinymce-rails'
gem 'whenever', require: false
