# frozen_string_literal: true

require 'test_helper'

module Contests
  class PrizePoolComponentTest < ViewComponentTestCase
    test 'hides a zero donation line' do
      contest = contests(:results)
      contest.update!(donations_uah: 0, prize_pool_uah: 500)

      render_inline(PrizePoolComponent.new(presenter: ShowPresenter.new(contest:, user: nil)))

      assert_text 'гарантовано 500 ₴'
      assert_no_text 'донати'
    end

    test 'support link carries a coffee icon' do
      contest = contests(:results)
      contest.update!(donation_url: 'https://buymeacoffee.com/bakainua')

      render_inline(PrizePoolComponent.new(presenter: ShowPresenter.new(contest:, user: nil)))

      assert_selector 'a[href="https://buymeacoffee.com/bakainua"] svg[aria-hidden="true"]'
      assert_text 'Підтримати фонд'
    end

    test 'lists places without money as one range' do
      contest = contests(:results)
      contest.prizes.create!(position: 2, title: '2 місце', kind: :place, place: 2, cash_uah: 0, perks: 'згадка')
      contest.prizes.create!(position: 3, title: '3 місце', kind: :place, place: 3, cash_uah: 0, perks: 'згадка')

      render_inline(PrizePoolComponent.new(presenter: ShowPresenter.new(contest:, user: nil)))

      assert_text '2–3 місця'
      assert_text '1 500 ₴'
      assert_text 'Вибір читачів'
    end

    test 'shows donations when readers added to the pool' do
      contest = contests(:results)
      contest.update!(donations_uah: 180, prize_pool_uah: 500)

      render_inline(PrizePoolComponent.new(presenter: ShowPresenter.new(contest:, user: nil)))

      assert_text 'гарантовано 500 ₴ · донати 180 ₴'
    end
  end
end
