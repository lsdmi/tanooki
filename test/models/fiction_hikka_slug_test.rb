# frozen_string_literal: true

require 'test_helper'

class FictionHikkaSlugTest < ActiveSupport::TestCase
  setup do
    FakeHikkaLookup.reset!
  end

  test 'input is stored as a bare slug, and blank input clears the field' do
    fiction = fictions(:one)
    fiction.hikka_slug = 'https://hikka.io/novel/Guimi-Zhi-Zhu-7059fd/'

    assert_equal 'guimi-zhi-zhu-7059fd', fiction.hikka_slug

    fiction.hikka_slug = '   '

    assert_nil fiction.hikka_slug
  end

  test 'values that are not a novel slug are rejected by format' do
    with_lookup do
      fiction = fictions(:one)
      ['https://hikka.io/manga/abc', 'Hello World', "a#{'-' * 255}"].each do |value|
        fiction.hikka_slug = value
        fiction.valid?

        assert_predicate fiction.errors[:hikka_slug], :any?, value
      end
    end
  end

  test 'two fictions cannot share one Hikka slug' do
    fictions(:one).update_column(:hikka_slug, 'taken-slug')
    fiction = fictions(:two)
    fiction.hikka_slug = 'taken-slug'

    with_lookup(result: ->(*) { raise 'Hikka should not be asked for a taken slug' }) do
      fiction.valid?
    end

    assert_predicate fiction.errors[:hikka_slug], :any?
    assert_equal 0, FakeHikkaLookup.calls
  end

  test 'fictions without a Hikka slug do not conflict' do
    fictions(:one).update_column(:hikka_slug, nil)
    fiction = fictions(:two)
    fiction.hikka_slug = nil

    fiction.valid?

    assert_empty fiction.errors[:hikka_slug]
  end

  test 'a slug Hikka does not know is rejected' do
    with_lookup(result: :not_found) do
      fiction = fictions(:two)
      fiction.hikka_slug = 'no-such-novel-000000'

      fiction.valid?

      assert_includes fiction.errors[:hikka_slug], hikka_slug_message(:not_found_on_hikka)
      assert_nil fiction.hikka_slug_warning
    end
  end

  test 'a slug Hikka confirms is accepted without a warning' do
    with_lookup(result: :found) do
      fiction = fictions(:two)
      fiction.hikka_slug = 'guimi-zhi-zhu-7059fd'

      fiction.valid?

      assert_empty fiction.errors[:hikka_slug]
      assert_nil fiction.hikka_slug_warning
    end
  end

  test 'an unreachable Hikka does not block the save but leaves a warning' do
    with_lookup(result: :unavailable) do
      fiction = fictions(:two)
      fiction.hikka_slug = 'guimi-zhi-zhu-7059fd'

      fiction.valid?

      assert_empty fiction.errors[:hikka_slug]
      assert_equal :hikka_unavailable, fiction.hikka_slug_warning
    end
  end

  test 'soft-deleting a fiction releases its Hikka slug for another fiction' do
    fiction = fictions(:one)
    fiction.update_column(:hikka_slug, 'guimi-zhi-zhu-7059fd')

    fiction.destroy

    assert_nil Fiction.with_deleted.find(fiction.id).hikka_slug
    other = fictions(:two)
    other.hikka_slug = 'guimi-zhi-zhu-7059fd'
    with_lookup(result: :found) { other.valid? }

    assert_empty other.errors[:hikka_slug]
  end

  test 'Hikka is not asked when the slug has not changed' do
    fiction = fictions(:one)
    fiction.update_column(:hikka_slug, 'guimi-zhi-zhu-7059fd')
    fiction.reload

    with_lookup(result: ->(*) { raise 'Hikka should not be asked' }) do
      fiction.valid?
    end

    assert_equal 0, FakeHikkaLookup.calls
  end

  test 'Hikka is asked once per value even when the record validates twice' do
    fiction = fictions(:two)
    fiction.hikka_slug = 'guimi-zhi-zhu-7059fd'

    with_lookup(result: :found) do
      fiction.valid?
      fiction.valid?
    end

    assert_equal 1, FakeHikkaLookup.calls
  end

  private

  def hikka_slug_message(key)
    I18n.t(key, scope: 'activerecord.errors.models.fiction.attributes.hikka_slug')
  end

  def with_lookup(result: :found, &)
    FakeHikkaLookup.result = result
    Fictions::HikkaLookup.stub(:new, ->(slug) { FakeHikkaLookup.new(slug) }, &)
  end
end
