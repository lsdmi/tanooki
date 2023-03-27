# frozen_string_literal: true

require_relative '../../app/jobs/application_job'
require_relative '../../app/jobs/elasticsearch_checker_job'

ElasticsearchCheckerJob.set(wait: 3.hours).perform_later
