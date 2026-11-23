# frozen_string_literal: true

require 'test_helper'

class FictionTagLinkTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
    @tag = fiction_tags(:rebirth)
  end

  test 'fiction exposes tags through links' do
    @fiction.fiction_tags << @tag

    assert_includes @fiction.reload.fiction_tags, @tag
    assert_includes @tag.reload.fictions, @fiction
  end

  test 'counter cache tracks linked fictions' do
    link = FictionTagLink.create!(fiction: @fiction, fiction_tag: @tag)

    assert_equal 1, @tag.reload.fictions_count

    link.destroy

    assert_equal 0, @tag.reload.fictions_count
  end

  test 'same tag cannot be linked twice to one fiction' do
    FictionTagLink.create!(fiction: @fiction, fiction_tag: @tag)
    duplicate = FictionTagLink.new(fiction: @fiction, fiction_tag: @tag)

    assert_not duplicate.valid?
    assert_includes duplicate.errors.details[:fiction_tag_id].pluck(:error), :taken
  end

  test 'a fiction holds at most MAX_PER_FICTION tags' do
    FictionTag::MAX_PER_FICTION.times do |index|
      FictionTagLink.create!(fiction: @fiction, fiction_tag: FictionTag.create!(name: "Теґ #{index}"))
    end
    extra = FictionTagLink.new(fiction: @fiction, fiction_tag: @tag)

    assert_not extra.valid?
    assert_includes extra.errors.details[:fiction].pluck(:error), :too_many_tags
  end

  test 'soft-deleting a fiction removes its links and decrements the counter' do
    @fiction.fiction_tags << @tag

    assert_difference -> { FictionTagLink.count }, -1 do
      @fiction.destroy
    end
    assert_predicate @fiction.reload, :deleted?
    assert_equal 0, @tag.reload.fictions_count
  end
end
