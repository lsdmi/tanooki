# frozen_string_literal: true

require 'test_helper'

module Publications
  class PersistReleaseTimeTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @publication = Publication.new(user: @user)
    end

    test 'publishing a draft stamps published_at now and keeps created_at' do
      create_old_draft
      created_at = @publication.reload.created_at

      saved = publish

      assert saved
      assert_in_delta created_at, @publication.reload.created_at, 1.second
      assert_in_delta Time.current, @publication.published_at, 2.seconds
    end

    test 'editing a live publication does not bump published_at' do
      publish
      original = @publication.reload.published_at

      travel_to 1.hour.from_now do
        saved = Persist.call(
          publication: @publication,
          attributes: persist_attrs(title: 'Edited live publication title'),
          intent: 'publish'
        )

        assert saved
        assert_in_delta original, @publication.reload.published_at, 1.second
      end
    end

    test 'returning a live publication to a draft clears published_at' do
      publish
      saved = Persist.call(
        publication: @publication,
        attributes: persist_attrs(title: 'Now a draft blog title'),
        intent: 'draft'
      )

      assert saved
      assert_predicate @publication.reload, :draft?
      assert_nil @publication.published_at
    end

    private

    def create_old_draft
      travel_to 3.days.ago do
        Persist.call(
          publication: @publication,
          attributes: persist_attrs(cover: nil, description: 'short', title: 'Draft blog title'),
          intent: 'draft'
        )
      end
    end

    def publish
      Persist.call(publication: @publication, attributes: persist_attrs, intent: 'publish')
    end

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
