# frozen_string_literal: true

require 'propshaft_dev_manifest'

if Rails.env.development?
  Rails.application.config.after_initialize do
    PropshaftDevManifest.refresh_if_stale!
  end

  ActiveSupport.on_load(:action_controller_base) do
    before_action { PropshaftDevManifest.refresh_if_stale! }
  end
end
