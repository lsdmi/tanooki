# frozen_string_literal: true

require 'test_helper'

module Fictions
  class MergedRedirectTest < ActiveSupport::TestCase
    test 'follows a short chain to the live fiction' do
      live = fictions(:one)
      middle = deleted_fiction('middle', merged_into: live)
      source = deleted_fiction('source', merged_into: middle)

      assert_equal live, MergedRedirect.new(source.slug).target
    end

    test 'stops after a few hops' do
      live = fictions(:one)
      current = live
      MergedRedirect::MAX_HOPS.succ.times do |index|
        current = deleted_fiction("hop-#{index}", merged_into: current)
      end

      assert_nil MergedRedirect.new(current.slug).target
    end

    test 'returns nothing for a deleted fiction that was not merged' do
      source = fictions(:two)
      source.destroy!

      assert_nil MergedRedirect.new(source.slug).target
    end

    private

    def deleted_fiction(slug, merged_into:)
      fiction = Fiction.new(slug:, title: slug, author: 'Author Name', description: 'd' * 30)
      fiction.merged_into = merged_into
      fiction.deleted_at = Time.current
      fiction.save!(validate: false)
      fiction
    end
  end
end
