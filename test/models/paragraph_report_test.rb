# frozen_string_literal: true

require 'test_helper'

class ParagraphReportTest < ActiveSupport::TestCase
  setup do
    @chapter = chapters(:one)
    @user = users(:user_two)
    @attrs = {
      user: @user,
      chapter: @chapter,
      block_index: 0,
      quote: 'Перший абзац із помилкою',
      digest: 'a' * ParagraphReport::DIGEST_LENGTH
    }
  end

  test 'a valid open report persists' do
    report = ParagraphReport.create!(@attrs)

    assert_predicate report, :open?
    assert_equal 0, report.block_index
  end

  test 'quote digest block_index and message are validated' do
    invalid = [
      ParagraphReport.new(@attrs.merge(quote: ' ')),
      ParagraphReport.new(@attrs.merge(quote: 'я' * (ParagraphReport::QUOTE_MAX + 1))),
      ParagraphReport.new(@attrs.merge(digest: 'short')),
      ParagraphReport.new(@attrs.merge(block_index: -1)),
      ParagraphReport.new(@attrs.merge(message: 'м' * (ParagraphReport::MESSAGE_MAX + 1)))
    ]

    assert(invalid.none?(&:valid?))
    assert_predicate invalid.first.errors[:quote], :any?
  end

  test 'open and resolved scopes' do
    open_report = ParagraphReport.create!(@attrs)
    fixed = ParagraphReport.create!(@attrs.merge(block_index: 1, status: :fixed, resolved_at: Time.current))

    assert_equal(
      [true, false, true, false],
      [ParagraphReport.open.include?(open_report), ParagraphReport.open.include?(fixed),
       ParagraphReport.resolved.include?(fixed), ParagraphReport.resolved.include?(open_report)]
    )
  end

  test 'for_scanlator_ids scopes to team chapters' do
    report = ParagraphReport.create!(@attrs)

    assert_includes ParagraphReport.for_scanlator_ids([scanlators(:one).id]), report
    assert_empty ParagraphReport.for_scanlator_ids([scanlators(:two).id])
  end

  test 'really destroying the chapter removes its reports' do
    chapter = Chapter.create!(
      fiction: fictions(:one),
      user: users(:user_one),
      title: 'Temp chapter for report destroy',
      number: 99,
      scanlator_ids: [scanlators(:one).id],
      status: :draft,
      content: 'x' * 500
    )
    ParagraphReport.create!(@attrs.merge(chapter:))

    assert_difference('ParagraphReport.count', -1) { chapter.really_destroy! }
  end

  test 'a fixed report does not block a new open on the same anchor' do
    ParagraphReport.create!(@attrs.merge(status: :fixed, resolved_at: Time.current))

    assert_difference('ParagraphReport.count') { ParagraphReport.create!(@attrs) }
  end
end
