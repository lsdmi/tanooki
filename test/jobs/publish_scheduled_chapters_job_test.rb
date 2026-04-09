# frozen_string_literal: true

require 'test_helper'

class PublishScheduledChaptersJobTest < ActiveJob::TestCase
  test 'publishes chapters whose publish_at has passed' do
    chapter = chapters(:scheduled)
    chapter.update_column(:publish_at, 1.hour.ago)

    PublishScheduledChaptersJob.perform_now

    chapter.reload
    assert_nil chapter.publish_at
    assert chapter.published?
  end

  test 'does not publish chapters whose publish_at is in the future' do
    chapter = chapters(:scheduled)
    original_publish_at = chapter.publish_at

    PublishScheduledChaptersJob.perform_now

    chapter.reload
    assert_equal original_publish_at, chapter.publish_at
    assert chapter.scheduled?
  end
end
