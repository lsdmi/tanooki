# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerShowParagraphReportTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chapter = chapters(:one)
  end

  test 'a guest sees the paragraph report sheet with login CTA' do
    get chapter_url(@chapter)

    assert_response :success
    assert_select '#paragraph-report[data-controller=paragraph-report]'
    assert_select '#paragraph-report a', text: /Увійдіть, щоб повідомити про помилку/
  end

  test 'a reader sees the report form sheet' do
    sign_in users(:user_two)

    get chapter_url(@chapter)

    assert_select '#paragraph-report form[data-paragraph-report-target=form]'
    assert_select '#paragraph-report textarea#paragraph-report-message'
  end

  test 'the team does not get the report sheet' do
    sign_in users(:user_one)

    get chapter_url(@chapter)

    assert_select '#paragraph-report', count: 0
  end

  test 'an 18+ locked chapter still embeds the sheet outside the blurred prose' do
    sign_in users(:user_two)
    @chapter.fiction.update!(content_rating: :eighteen)

    get chapter_url(@chapter)

    assert_select '.adult-content-gate--locked #user-content'
    assert_select '#paragraph-report[data-controller=paragraph-report]'
    assert_select '.adult-content-gate--locked #paragraph-report', count: 0
  end

  test 'open reports paint public marks with messages outside the body cache' do
    digest = Chapters::ReaderContentHtml.new(@chapter).digest
    ParagraphReport.create!(
      user: users(:user_two),
      chapter: @chapter,
      block_index: 0,
      quote: 'Цитата',
      digest: digest,
      message: 'Тут калька'
    )

    get chapter_url(@chapter)

    assert_response :success
    assert_select '.immersive-reader[data-controller~=paragraph-report-marks]' \
                  '[data-paragraph-report-marks-items-value=?]',
                  %([{"i":0,"m":[{"u":"#{users(:user_two).name}","t":"Тут калька"}]}])
    assert_select '.immersive-reader[data-paragraph-report-marks-heading-value]', count: 1
  end

  test 'stale digest reports do not add public marks' do
    ParagraphReport.create!(
      user: users(:user_two),
      chapter: @chapter,
      block_index: 0,
      quote: 'Цитата',
      digest: 'z' * ParagraphReport::DIGEST_LENGTH,
      message: 'Старий текст'
    )

    get chapter_url(@chapter)

    assert_response :success
    assert_select '.immersive-reader[data-controller~=paragraph-report-marks]', count: 0
  end
end
