# frozen_string_literal: true

require 'test_helper'

module Publications
  class PersistTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @publication = Publication.new(user: @user)
    end

    test 'draft intent skips cover description and title minimums' do
      saved = Persist.call(
        publication: @publication,
        attributes: persist_attrs(cover: nil, description: 'short', title: 'Hi'),
        intent: 'draft'
      )

      assert saved
      assert_predicate @publication, :draft?
      assert_equal 'Hi', @publication.title
    end

    test 'blank title on draft becomes placeholder' do
      saved = Persist.call(
        publication: @publication,
        attributes: persist_attrs(cover: nil, description: '', title: ''),
        intent: 'draft'
      )

      assert saved
      assert_equal I18n.t('publications.placeholder_title'), @publication.title
      assert_predicate @publication.slug, :present?
    end

    test 'unknown intent publishes' do
      saved = Persist.call(
        publication: @publication,
        attributes: persist_attrs,
        intent: 'nope'
      )

      assert saved
      assert_predicate @publication, :published?
    end

    test 'publish intent still requires description cover and title minimums' do
      saved = Persist.call(
        publication: @publication,
        attributes: persist_attrs(cover: nil, description: 'short', title: 'Hi'),
        intent: 'publish'
      )

      assert_not saved
      assert_predicate @publication, :published?
    end

    test 'failed publish on an existing draft keeps draft status for redisplay' do
      Persist.call(
        publication: @publication,
        attributes: persist_attrs(cover: nil, description: 'short', title: 'Draft blog'),
        intent: 'draft'
      )

      saved = Persist.call(
        publication: @publication,
        attributes: persist_attrs(cover: nil, description: 'short', title: 'Draft blog'),
        intent: 'publish'
      )

      assert_not saved
      assert_predicate @publication, :draft?
    end

    test 'successful persist busts public list caches' do
      Rails.cache.write(PublicCache::HIGHLIGHTS_KEY, ['stale'])

      saved = Persist.call(publication: @publication, attributes: persist_attrs, intent: 'publish')

      assert saved
      assert_nil Rails.cache.read(PublicCache::HIGHLIGHTS_KEY)
    end

    test 'draft intent unpublishes a live publication' do
      Persist.call(publication: @publication, attributes: persist_attrs, intent: 'publish')
      saved = Persist.call(
        publication: @publication,
        attributes: persist_attrs(title: 'Now a draft blog title'),
        intent: 'draft'
      )

      assert saved
      assert_predicate @publication.reload, :draft?
    end

    test 'publishing a placeholder draft regenerates slug from the new title' do
      Persist.call(
        publication: @publication,
        attributes: persist_attrs(cover: nil, description: 'short', title: ''),
        intent: 'draft'
      )
      placeholder_slug = @publication.slug

      saved = Persist.call(
        publication: @publication,
        attributes: persist_attrs(title: 'A distinctive published blog title'),
        intent: 'publish'
      )

      assert saved
      assert_not_equal placeholder_slug, @publication.reload.slug
    end

    private

    def persist_attrs(**overrides)
      {
        type: 'Tale',
        title: 'A valid publication title',
        description: 'x' * 500,
        cover: Rack::Test::UploadedFile.new(
          Rails.root.join('app/assets/images/logo-default.svg'),
          'image/svg'
        )
      }.merge(overrides)
    end
  end
end
