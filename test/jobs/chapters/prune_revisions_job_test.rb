# frozen_string_literal: true

require 'test_helper'

module Chapters
  class PruneRevisionsJobTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_two)
      @token = ApiToken.issue!(user: @user, name: 'Claude', scopes: %w[chapters:read chapters:write])
      @chapter = Api::Chapters::Create.call(
        user: @user, token: @token, fiction_id: fictions(:eighteen).id,
        params: { number: 32, title: 'Історія', content: 'Текст.', scanlator_ids: [scanlators(:two).id] }
      ).chapter
    end

    test 'revisions older than 90 days are removed' do
      revision = ChapterRevision.create!(
        chapter: @chapter, user: @user, title: 'Старе', body: 'Текст.', created_at: 91.days.ago
      )

      PruneRevisionsJob.perform_now

      assert_not ChapterRevision.exists?(revision.id)
    end

    test 'only the newest 20 revisions stay' do
      21.times do |index|
        ChapterRevision.create!(chapter: @chapter, user: @user, title: "Крок #{index}", body: 'Текст.')
      end

      PruneRevisionsJob.perform_now

      assert_equal 20, @chapter.revisions.count
    end
  end
end
