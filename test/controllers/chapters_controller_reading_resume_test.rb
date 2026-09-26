# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerReadingResumeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  RESUME_ROOT = '.immersive-reader[data-controller~=reading-resume]'
  BANNER = 'section[data-reading-resume-target=banner]'

  setup do
    sign_in users(:user_one)
    @chapter = chapters(:one)
    @progress = reading_progresses(:one)
    @progress.update!(chapter: @chapter, resume_quote: 'Початок', resume_block_index: 3, resume_percent: 42.5,
                      resume_digest: 'a' * 16)
  end

  test 'resume visit of the resume chapter restores straight away with the stored locator' do
    get chapter_url(@chapter, resume: 1)

    assert_select "#{RESUME_ROOT}[data-reading-resume-auto-value=true][data-reading-resume-quote-value=?]", 'Початок'
    assert_select "#{RESUME_ROOT}[data-reading-resume-block-index-value='3']" \
                  "[data-reading-resume-percent-value='42.5'][data-reading-resume-digest-value=?]", 'a' * 16
    assert_select "#{BANNER}, [data-reading-progress-hold-value]", count: 0
  end

  test 'opening the resume chapter without the flag offers the banner and holds position capture' do
    get chapter_url(@chapter)

    assert_select "#{RESUME_ROOT}[data-reading-resume-auto-value=false][data-reading-progress-hold-value=true]"
    assert_select "#{BANNER}[hidden] button" do |buttons|
      assert_equal([['reading-resume#resume', 'Продовжити з 43%'], ['reading-resume#dismiss', 'З початку']],
                   buttons.map { [it['data-action'], it.text.strip] })
    end
  end

  test 'a chapter the cursor is not on neither restores nor offers' do
    get chapter_url(chapters(:two), resume: 1)

    assert_select RESUME_ROOT, count: 0

    get chapter_url(chapters(:two))

    assert_select "#{RESUME_ROOT}, #{BANNER}", count: 0
  end

  test 'no stored position means no restore and no banner' do
    @progress.update!(resume_percent: nil)
    get chapter_url(@chapter, resume: 1)

    assert_select RESUME_ROOT, count: 0

    get chapter_url(@chapter)

    assert_select "#{RESUME_ROOT}, #{BANNER}", count: 0
  end

  test 'guests never restore' do
    sign_out :user
    get chapter_url(@chapter, resume: 1)

    assert_select RESUME_ROOT, count: 0
  end

  test 'a position at the very start is not worth a banner but still restores from continue' do
    @progress.update!(resume_percent: 0.4)
    get chapter_url(@chapter)

    assert_select "#{RESUME_ROOT}, #{BANNER}", count: 0

    get chapter_url(@chapter, resume: 1)

    assert_select "#{RESUME_ROOT}[data-reading-resume-percent-value='0.4']"
  end

  test 'a finished position gets no banner' do
    @progress.update!(resume_percent: Reading::ContinueTarget::FINISHED_PERCENT)
    get chapter_url(@chapter)

    assert_select "#{RESUME_ROOT}, #{BANNER}", count: 0
  end

  test 'a locator with only a percent omits the other values' do
    @progress.update!(resume_quote: nil, resume_block_index: nil, resume_digest: nil)
    get chapter_url(@chapter, resume: 1)

    assert_select "#{RESUME_ROOT}[data-reading-resume-percent-value='42.5']"
    assert_select '[data-reading-resume-quote-value], [data-reading-resume-block-index-value]', count: 0
  end
end
