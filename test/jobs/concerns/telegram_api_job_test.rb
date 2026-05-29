# frozen_string_literal: true

require 'test_helper'

class TelegramApiJobTest < ActiveSupport::TestCase
  test 'telegram digest jobs include TelegramApiJob' do
    [Youtube::TelegramJob, FictionsTelegramJob, PublicationsTelegramJob, WeeklyStatsTelegramJob].each do |job|
      assert_includes job.ancestors, TelegramApiJob, "#{job} should include TelegramApiJob"
    end
  end

  test 'telegram digest jobs include ExternalApiResilience via TelegramApiJob' do
    assert_includes FictionsTelegramJob.ancestors, ExternalApiResilience
  end
end
