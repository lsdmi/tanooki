# frozen_string_literal: true

require 'test_helper'

module Admin
  class ApiRollbacksControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @member = users(:user_two)
      @token = ApiToken.issue!(user: @member, name: 'Чат', scopes: %w[chapters:read chapters:write])
      @chapter = chapters(:one)
      @chapter.update!(status: :draft, title: 'Зараз', content: '<p>Зараз.</p>')
      ChapterRevision.create!(
        chapter: @chapter, user: @member, api_token: @token, title: 'Було', body: '<p>Було.</p>',
        created_at: 1.hour.ago, updated_at: 1.hour.ago
      )
    end

    test 'an admin sees a key that has stored a revision' do
      sign_in users(:user_one)

      get admin_api_rollbacks_url

      assert_response :success
      assert_select 'h3', text: @member.name
    end

    test 'an admin rolls a key back to the stored text' do
      sign_in users(:user_one)

      post admin_api_rollbacks_url, params: { api_token_id: @token.id, since: 2.hours.ago.iso8601 }

      assert_redirected_to admin_api_rollbacks_path
      assert_equal 'Було', @chapter.reload.title
    end

    test 'a member cannot open the rollback page' do
      sign_in @member

      get admin_api_rollbacks_url

      assert_redirected_to root_path
    end
  end
end
