# frozen_string_literal: true

require 'test_helper'

class ContestsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'index is hidden from guests while contests are unlisted' do
    get contests_path

    assert_response :not_found
  end

  test 'show is hidden from guests while contests are unlisted' do
    get contest_path(contests(:submissions))

    assert_response :not_found
  end

  test 'non-admin cannot open contest pages while unlisted' do
    sign_in users(:user_two)

    get contests_path

    assert_response :not_found

    get contest_path(contests(:submissions))

    assert_response :not_found
  end

  test 'admin can open hub while unlisted' do
    sign_in users(:user_one)

    get contests_path

    assert_response :success
    assert_select '.contests-page'
  end

  test 'admin can open show while unlisted' do
    sign_in users(:user_one)

    get contest_path(contests(:submissions))

    assert_response :success
    %w[#hero #summary #sections].each { |selector| assert_select selector }
  end

  test 'admin show puts results under hero' do
    sign_in users(:user_one)

    get contest_path(contests(:results))

    assert_response :success
    assert_select '#results'
    assert_select '#hero + * #results, #results', minimum: 1
  end

  test 'admin show works for cancelled contests' do
    sign_in users(:user_one)

    get contest_path(contests(:cancelled))

    assert_response :success
    assert_select '#cancelled'
  end

  test 'draft contest is not found for guests' do
    get contest_path(contests(:draft))

    assert_response :not_found
  end

  test 'non-admin cannot see draft' do
    sign_in users(:user_two)

    get contest_path(contests(:draft))

    assert_response :not_found
  end

  test 'admin can preview draft and marks readiness previewed' do
    sign_in users(:user_one)
    contest = contests(:draft)

    get contest_path(contest)

    assert_response :success
    assert_predicate Contests::Readiness.new(contest.reload), :previewed?
  end

  test 'admin hub shows teaser text for unpublished draft when idle' do
    sign_in users(:user_one)
    Contest.active.find_each { |contest| contest.update!(cancelled_at: Time.current) }
    contests(:draft).update!(teaser_text: 'Скоро новий Поріг')

    get contests_path

    assert_response :success
    assert_select 'p', text: 'Скоро новий Поріг'
  end

  test 'unknown slug is not found' do
    sign_in users(:user_one)

    get contest_path('no-such-contest')

    assert_response :not_found
  end

  test 'when listed, signed-in participant sees my participation' do
    with_contests_listed do
      reader = users(:user_two)
      contest_entries(:accepted).update!(submitter_id: reader.id)
      sign_in reader

      get contest_path(contests(:submissions))

      assert_response :success
      assert_select '#my-entry'
    end
  end

  test 'when listed, guests can open the hub' do
    with_contests_listed do
      get contests_path

      assert_response :success
      assert_select '.contests-page'
    end
  end
end
