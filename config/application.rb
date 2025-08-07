# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Tanooki
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    config.i18n.default_locale = :uk
    config.i18n.available_locales = %i[uk en]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Europe/Kiev'
    # config.eager_load_paths << Rails.root.join('extras')

    config.active_storage.variant_processor = :mini_magick
    config.autoload_paths += %W[#{config.root}/app/services]
    config.autoload_paths += %W[#{config.root}/app/query]
    config.autoload_paths += %W[#{config.root}/app/forms]
  end
end

Rails.configuration.after_initialize do
  ActionText::RichText.class_eval do
    acts_as_paranoid

    default_scope -> { where(deleted_at: nil) }
  end

  ActiveStorage::Attachment.class_eval do
    acts_as_paranoid

    default_scope -> { where(deleted_at: nil) }
  end

  ActiveStorage::Blob.class_eval do
    acts_as_paranoid

    default_scope -> { where(deleted_at: nil) }
  end
end
