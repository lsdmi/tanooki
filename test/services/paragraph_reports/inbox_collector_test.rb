# frozen_string_literal: true

require 'test_helper'

module ParagraphReports
  class InboxCollectorTest < ActiveSupport::TestCase
    setup do
      @digest = 'c' * ParagraphReport::DIGEST_LENGTH
      @team_report = ParagraphReport.create!(
        user: users(:user_two),
        chapter: chapters(:one),
        block_index: 0,
        quote: 'Абзац команди',
        digest: @digest
      )
    end

    test 'a team member sees open reports for their scanlator chapters' do
      member = users(:user_one)
      member.update!(admin: false)

      assert_includes InboxCollector.new(member).call, @team_report
    end

    test 'a member of another team does not see foreign reports' do
      outsider = users(:user_two)

      assert_empty InboxCollector.new(outsider).call
    end

    test 'an admin sees all open reports' do
      assert_includes InboxCollector.new(users(:user_one)).call, @team_report
    end

    test 'resolved reports are excluded' do
      @team_report.update!(status: :fixed, resolved_at: Time.current)

      assert_empty InboxCollector.new(users(:user_one)).call
    end

    test 'open_count matches the relation' do
      assert_equal 1, InboxCollector.new(users(:user_one)).open_count
    end

    test 'latest_open_id is the newest open report in scope' do
      newer = ParagraphReport.create!(
        user: users(:user_two),
        chapter: chapters(:one),
        block_index: 2,
        quote: 'Новіший',
        digest: @digest
      )

      assert_equal newer.id, InboxCollector.new(users(:user_one)).latest_open_id
    end

    test 'groups collapse the same block and digest from different readers' do
      other = users('user_101')
      second = ParagraphReport.create!(
        user: other,
        chapter: chapters(:one),
        block_index: 0,
        quote: 'Абзац команди',
        digest: @digest,
        message: 'Інший погляд'
      )
      ParagraphReport.create!(
        user: users(:user_two),
        chapter: chapters(:one),
        block_index: 1,
        quote: 'Інший абзац',
        digest: @digest
      )

      grouped = InboxCollector.new(users(:user_one)).groups.find { |group| group.block_index.zero? }

      assert_equal [@team_report.id, second.id].sort, grouped.report_ids.sort
      assert_equal(
        [2, chapters(:one).title, [users(:user_two).name, other.name].sort],
        [grouped.size, grouped.chapter.title, grouped.reporters.map(&:name).sort]
      )
      # Studio cards render reporter avatars from this preload.
      assert_equal grouped.reporters.size, grouped.reporters.count(&:avatar)
    end
  end
end
