# frozen_string_literal: true

require 'test_helper'

module Admin
  class RollbackTokenChangesTest < ActiveSupport::TestCase
    setup do
      @admin = users(:user_one)
      @member = users(:user_two)
      @token = ApiToken.issue!(user: @member, name: 'Чат', scopes: %w[chapters:read chapters:write])
      @chapter = chapters(:one)
      @chapter.update!(status: :draft, title: 'Зараз', content: '<p>Зараз.</p>')
    end

    test 'restores the text from before the first change in the window' do
      snapshot(@token, 'Давно', '<p>Давно.</p>', 3.hours.ago)
      snapshot(@token, 'Недавно', '<p>Недавно.</p>', 1.hour.ago)

      scope = ChapterRevision.where(api_token: @token)
      result = RollbackTokenChanges.call(admin: @admin, revisions: scope, since: 2.hours.ago)

      assert_equal 1, result.restored
      assert_equal 'Недавно', @chapter.reload.title
      assert_includes @chapter.content_html, 'Недавно'
    end

    test 'a connected chat revision is listed with that chat' do
      access = oauth_access
      Api::Chapters::Revisions.record!(@chapter, user: @member, token: access)

      source = ApiChangeSources.oauth.sole

      assert_equal access.application_id, source.application.id
      assert_equal 1, source.count
    end

    test 'a published restore does not spend the member edit cap' do
      @chapter.update!(status: :published, title: 'Зараз', content: "<p>#{'А' * 500}</p>")
      snapshot(@token, 'Було', "<p>#{'Б' * 500}</p>", 1.hour.ago)
      fill_cap

      scope = ChapterRevision.where(api_token: @token)
      RollbackTokenChanges.call(admin: @admin, revisions: scope, since: 2.hours.ago)

      assert_equal 'Було', @chapter.reload.title
      assert_equal Api::Limits::PUBLISHED_EDITS_PER_HOUR, cap_count
    end

    private

    def oauth_access
      application = Doorkeeper::Application.create!(
        name: 'ChatGPT', redirect_uri: 'https://chatgpt.com/connector/oauth/callback',
        uid: "app-#{SecureRandom.hex(8)}", secret: SecureRandom.hex(16)
      )
      record = Doorkeeper::AccessToken.create!(
        application:, resource_owner_id: @member.id, token: SecureRandom.hex(16),
        expires_in: 2.hours.to_i, scopes: 'chapters:read chapters:write'
      )
      Api::OauthAccess.new(record, @member)
    end

    def snapshot(token, title, body, at)
      ChapterRevision.create!(
        chapter: @chapter, user: @member, api_token: token, title:, body:, created_at: at, updated_at: at
      )
    end

    def fill_cap
      Rails.cache.write(cap_key, Api::Limits::PUBLISHED_EDITS_PER_HOUR)
    end

    def cap_count
      Rails.cache.read(cap_key)
    end

    def cap_key
      Api::Limits.counter_key(:published_edit_hour, @member, Api::Limits::PublishedEdits.hour_period)
    end
  end
end
