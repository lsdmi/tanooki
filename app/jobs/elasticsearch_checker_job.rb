# frozen_string_literal: true

class ElasticsearchCheckerJob < ApplicationJob
  queue_as :default

  def perform
    output = 'sudo systemctl status elasticsearch'

    return if output.include?('Active: active (running)')

    'sudo systemctl start elasticsearch'
  end
end
