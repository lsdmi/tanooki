# frozen_string_literal: true

Rails.application.config.active_job.queue_adapter = :async
Rails.application.config.active_job.queue_name_prefix = Rails.env
