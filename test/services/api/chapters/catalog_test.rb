# frozen_string_literal: true

require 'test_helper'

module Api
  module Chapters
    class CatalogTest < ActiveSupport::TestCase
      setup do
        @user = users(:user_two)
        FictionScanlator.create!(fiction: fictions(:eighteen), scanlator: scanlators(:two))
        @chapter = Create.call(
          user: @user, token: ApiToken.issue!(user: @user, name: 'Claude', scopes: %w[chapters:write]),
          fiction_id: fictions(:eighteen).id,
          params: {
            number: 21, title: 'Було', content: "#{'а' * 50_000} з картинкою",
            scanlator_ids: [scanlators(:two).id]
          }
        ).chapter
      end

      test 'summaries omit version' do
        rows = Catalog.new(@user).summaries(fictions(:eighteen).id)

        assert_equal 1, rows.size
        assert_nil rows.first[:version]
      end

      test 'summaries do not query rich text bodies' do
        queries = []
        callback = ->(*, payload) { queries << payload[:sql] }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          Catalog.new(@user).summaries(fictions(:eighteen).id)
        end

        assert(queries.none? { |sql| sql.match?(/action_text_rich_texts/i) })
        assert_operator @chapter.content.body.to_s.bytesize, :>, 40_000
      end
    end
  end
end
