# frozen_string_literal: true

require 'test_helper'

module Catalog
  class ApplyLicenseTest < ActiveSupport::TestCase
    SOURCE = { publisher: 'Видавництво Тест', url: 'https://example.test/book' }.freeze

    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
      @admin = users(:user_one)
      @editor = users(:user_two)
      ScanlatorUser.create!(user: @editor, scanlator: scanlators(:one))
    end

    test 'marking stamps licensed_at and records the source' do
      freeze_time do
        ApplyLicense.call(@fiction, actor: @editor, licensed: '1', **SOURCE)
        @fiction.save!

        assert_equal Time.current, @fiction.reload.licensed_at
        assert_equal SOURCE.values, [@fiction.license_publisher, @fiction.license_url]
      end
    end

    test 'marking again updates the source but keeps licensed_at' do
      freeze_time do
        license!(3.days.ago)

        ApplyLicense.call(@fiction, actor: @editor, licensed: true, publisher: 'Нове видавництво', url: '')
        @fiction.save!

        assert_equal 3.days.ago, @fiction.reload.licensed_at
        assert_equal ['Нове видавництво', nil], [@fiction.license_publisher, @fiction.license_url]
      end
    end

    test 'the team clears its own mark within the grace period' do
      license!(23.hours.ago)

      result = ApplyLicense.call(@fiction, actor: @editor, licensed: '0')
      @fiction.save!

      assert_not result.clear_denied?
      assert_equal [nil, nil, nil], license_columns
    end

    test 'the team cannot clear once the grace period is over' do
      license!(25.hours.ago)

      result = ApplyLicense.call(@fiction, actor: @editor, licensed: '0')

      assert_predicate result, :clear_denied?
      assert_predicate @fiction, :licensed?
    end

    test 'an outsider cannot clear even within the grace period' do
      license!(1.hour.ago)

      result = ApplyLicense.call(@fiction, actor: users(:user_one_one_zero), licensed: '0')

      assert_predicate result, :clear_denied?
      assert_predicate @fiction, :licensed?
    end

    test 'an admin clears all license fields after the grace period' do
      license!(3.days.ago)

      result = ApplyLicense.call(@fiction, actor: @admin, licensed: '0')
      @fiction.save!

      assert_not result.clear_denied?
      assert_equal [nil, nil, nil], license_columns
    end

    test 'marking reverts scheduled chapters to drafts' do
      scheduled = schedule!(chapters(:two))

      ApplyLicense.call(@fiction, actor: @editor, licensed: '1', **SOURCE)
      @fiction.save!

      assert_predicate scheduled.reload, :draft?
      assert_nil scheduled.published_at
      assert_equal 1, @fiction.reload.chapter_count
    end

    test 'marking leaves released chapters and completed_at alone' do
      completed_at = 2.days.ago.round
      @fiction.update!(completed_at:)

      ApplyLicense.call(@fiction, actor: @editor, licensed: '1', **SOURCE)
      @fiction.save!

      assert_predicate chapters(:one).reload, :public_visible?
      assert_equal completed_at, @fiction.reload.completed_at
    end

    private

    def license!(at = 3.days.ago)
      @fiction.update!(licensed_at: at, license_publisher: SOURCE[:publisher])
    end

    def schedule!(chapter)
      chapter.published_at = 2.days.from_now
      chapter.save!(validate: false)
      chapter
    end

    def license_columns
      @fiction.reload.attributes.values_at('licensed_at', 'license_publisher', 'license_url')
    end
  end
end
