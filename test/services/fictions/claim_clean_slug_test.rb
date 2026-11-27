# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ClaimCleanSlugTest < ActiveSupport::TestCase
    UUID = '9012a7a8-f286-40d2-8f24-374632cf5d6e'

    test 'renames a uuid slug and redirects the old one' do
      fiction = fictions(:one)
      old_slug = "clean-title-#{UUID}"
      assign_slug(fiction, old_slug)

      ClaimCleanSlug.new(fiction).call

      assert_equal 'clean-title', fiction.reload.slug
      assert_equal fiction, MergedRedirect.new(old_slug).target
    end

    test 'leaves the slug when the clean one is taken' do
      fiction = fictions(:one)
      old_slug = "taken-title-#{UUID}"
      assign_slug(fiction, old_slug)
      assign_slug(fictions(:two), 'taken-title')

      ClaimCleanSlug.new(fiction).call

      assert_equal old_slug, fiction.reload.slug
      assert_nil MergedRedirect.new(old_slug).target
    end

    test 'the redirect copy does not take the Hikka slug the live fiction holds' do
      fiction = fictions(:one)
      fiction.update_column(:hikka_slug, 'guimi-zhi-zhu-7059fd')
      old_slug = "clean-title-#{UUID}"
      assign_slug(fiction, old_slug)

      ClaimCleanSlug.new(fiction).call

      assert_equal 'clean-title', fiction.reload.slug
      assert_equal 'guimi-zhi-zhu-7059fd', fiction.hikka_slug
      assert_nil Fiction.with_deleted.find_by!(slug: old_slug).hikka_slug
    end

    test 'leaves a slug that has no uuid suffix' do
      fiction = fictions(:one)

      ClaimCleanSlug.new(fiction).call

      assert_equal 'one', fiction.reload.slug
    end

    private

    def assign_slug(fiction, slug)
      fiction.slug = slug
      fiction.save!(validate: false)
    end
  end
end
