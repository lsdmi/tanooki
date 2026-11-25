# frozen_string_literal: true

require 'test_helper'

class FictionTagRefreshTest < ActiveSupport::TestCase
  setup do
    @tag = fiction_tags(:rebirth)
    @tagged = fictions(:one)
    @other = fictions(:two)
    @tagged.fiction_tags << @tag
    @stamp = 1.day.ago
    [@tagged, @other].each { |fiction| fiction.update!(updated_at: @stamp) }
  end

  { name: 'Нове переродження', status: 'hidden', explicit: true }.each do |attribute, value|
    test "changing #{attribute} refreshes the works that carry the tag" do
      @tag.update!(attribute => value)

      assert_operator @tagged.reload.updated_at, :>, @stamp + 1.hour
      assert_in_delta @stamp, @other.reload.updated_at, 1
    end
  end

  test 'deleting the tag refreshes the works that carried it' do
    @tag.destroy!

    assert_operator @tagged.reload.updated_at, :>, @stamp + 1.hour
  end

  test 'a counter change alone does not refresh the works' do
    @other.fiction_tags << @tag

    assert_in_delta @stamp, @tagged.reload.updated_at, 1
  end
end
