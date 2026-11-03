# frozen_string_literal: true

require 'test_helper'

module Contests
  class RulesBuilderAndReadinessTest < ActiveSupport::TestCase
    include ReadyContestHelper

    setup do
      @contest = Contests::CreateFromPreset.call(
        preset: 'ranobe',
        submissions_open_at: 5.weeks.from_now.beginning_of_day,
        prize_pool_uah: 3000,
        title: 'Readiness тест'
      )
    end

    test 'changing general rules locale does not rewrite published snapshot' do
      snapshot = RulesBuilder.snapshot(@contest)
      @contest.update!(published_at: Time.current, rules_snapshot: snapshot)
      frozen = @contest.rules_snapshot.deep_dup

      I18n.backend.store_translations(:uk, contests: { rules: { intro: 'Змінений вступ' } })

      assert_equal frozen, @contest.reload.rules_snapshot
    ensure
      I18n.reload!
    end

    test 'readiness blocks publish for each missing item' do
      readiness = Readiness.new(@contest)

      %i[tagline description cover jurors previewed].each do |key|
        assert_includes readiness.missing_keys, key
      end
      assert_not readiness.ready?
    end

    test 'readiness is ready once every item is met' do
      @contest.update!(tagline: 'Слоган')
      @contest.update!(description: 'Тема конкурсу з підказками')
      attach_contest_cover!(@contest)
      add_contest_jurors!(@contest)
      Readiness.new(@contest).mark_previewed!

      assert_predicate Readiness.new(@contest.reload), :ready?
    end
  end
end
