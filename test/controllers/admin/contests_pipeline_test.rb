# frozen_string_literal: true

require 'test_helper'

module Admin
  class ContestsPipelineTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @admin = users(:user_one)
      sign_in @admin
    end

    test 'new_from_preset renders the form' do
      get new_from_preset_admin_contests_path

      assert_response :success
      assert_select 'form[action=?]', create_from_preset_admin_contests_path
    end

    test 'create_from_preset creates a draft' do
      assert_difference -> { Contest.count } => 1 do
        post_preset_contest
      end

      assert_redirected_to edit_admin_contest_path(Contest.order(:id).last)
    end

    test 'create_from_preset stores the preset key' do
      post_preset_contest

      assert_equal 'ranobe', Contest.order(:id).last.preset_key
    end

    test 'publish blocked until readiness green' do
      contest = ::Contests::CreateFromPreset.call(
        preset: 'ranobe',
        submissions_open_at: 5.weeks.from_now.beginning_of_day,
        prize_pool_uah: 3000,
        title: 'Блок публікації'
      )

      post publish_admin_contest_path(contest)

      assert_redirected_to admin_contest_path(contest)
      assert_nil contest.reload.published_at
      assert_match(/Ще не готово/, flash[:alert])
    end

    test 'duplicate creates draft' do
      assert_difference -> { Contest.count } => 1 do
        post duplicate_admin_contest_path(contests(:results))
      end

      assert_redirected_to edit_admin_contest_path(Contest.order(:id).last)
    end

    test 'duplicate links to the source and stays unpublished' do
      source = contests(:results)
      post duplicate_admin_contest_path(source)
      draft = Contest.order(:id).last

      assert_equal source.id, draft.source_contest_id
      assert_nil draft.published_at
    end

    private

    def post_preset_contest
      post create_from_preset_admin_contests_path, params: {
        preset_key: 'ranobe',
        submissions_open_at: 5.weeks.from_now.strftime('%Y-%m-%dT%H:%M'),
        prize_pool_uah: 3000,
        title: 'Адмін з шаблону'
      }
    end
  end
end
