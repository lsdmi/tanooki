# frozen_string_literal: true

# /admin/jobs is mounted behind a Devise admin check in config/routes.rb, so the gem's own HTTP basic auth stays off.
# Its controllers skip ApplicationController: the site layout helpers and error pages do not belong in the engine.
MissionControl::Jobs.http_basic_auth_enabled = false
MissionControl::Jobs.base_controller_class = 'ActionController::Base'
