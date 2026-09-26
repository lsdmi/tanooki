# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerReadingResumeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  RESUME_ROOT = '.immersive-reader[data-controller~=reading-resume]'

  setup do
    sign_in users(:user_one)
    @chapter = chapters(:one)
    @progress = reading_progresses(:one)
    @progress.update!(chapter: @chapter, resume_quote: 'Початок', resume_block_index: 3, resume_percent: 42.5,
                      resume_digest: 'a' * 16)
  end

  test 'resume visit of the resume chapter mounts the restore with the stored locator' do
    get chapter_url(@chapter, resume: 1)

    assert_select "#{RESUME_ROOT}[data-reading-resume-quote-value=?]", 'Початок'
    assert_select "#{RESUME_ROOT}[data-reading-resume-block-index-value='3']" \
                  "[data-reading-resume-percent-value='42.5'][data-reading-resume-digest-value=?]", 'a' * 16
  end

  test 'opening the chapter without the resume flag never restores' do
    get chapter_url(@chapter)

    assert_select RESUME_ROOT, count: 0
  end

  test 'resume flag on a chapter the cursor is not on does not restore' do
    get chapter_url(chapters(:two), resume: 1)

    assert_select RESUME_ROOT, count: 0
  end

  test 'resume flag without a stored position does not restore' do
    @progress.update!(resume_percent: nil)
    get chapter_url(@chapter, resume: 1)

    assert_select RESUME_ROOT, count: 0
  end

  test 'guests never restore' do
    sign_out :user
    get chapter_url(@chapter, resume: 1)

    assert_select RESUME_ROOT, count: 0
  end

  test 'a locator with only a percent omits the other values' do
    @progress.update!(resume_quote: nil, resume_block_index: nil, resume_digest: nil)
    get chapter_url(@chapter, resume: 1)

    assert_select "#{RESUME_ROOT}[data-reading-resume-percent-value='42.5']"
    assert_select '[data-reading-resume-quote-value], [data-reading-resume-block-index-value]', count: 0
  end
end
