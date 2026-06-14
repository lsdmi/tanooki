# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.9'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 8.0.0'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

gem 'mysql2'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 7.2'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem 'image_processing'

group :development, :test do
  gem 'debug'
end

group :development do
  gem 'brakeman', require: false
  gem 'bullet'
  gem 'bundler-audit'
  gem 'erb_lint', require: false
  gem 'letter_opener'
  gem 'lookbook'
  gem 'rails_best_practices'
  gem 'rubocop'
  gem 'rubocop-capybara', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'
end

group :test do
  gem 'minitest'
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'faker'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  gem 'simplecov'
end

group :production do
  gem 'aws-sdk-s3'
  gem 'solid_cache'
  gem 'solid_queue'
end

gem 'bcrypt_pbkdf'
gem 'devise'
gem 'dotenv-rails'
gem 'ed25519'
gem 'fastimage'
gem 'friendly_id'
gem 'gepub'
gem 'google-apis-youtube_v3'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'
gem 'opensearch-ruby'
gem 'pagy'
gem 'paranoia'
gem 'rails-i18n'
gem 'searchkick'
gem 'simple_form'
gem 'sqids'
gem 'tailwindcss-rails'
gem 'telegram-bot-ruby'
gem 'tinymce-rails'
gem 'view_component'
