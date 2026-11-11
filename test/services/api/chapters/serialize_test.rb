# frozen_string_literal: true

require 'test_helper'

module Api
  module Chapters
    class SerializeTest < ActiveSupport::TestCase
      setup do
        @user = users(:user_two)
        FictionScanlator.create!(fiction: fictions(:eighteen), scanlator: scanlators(:two))
        @chapter = Create.call(
          user: @user, token: ApiToken.issue!(user: @user, name: 'Claude', scopes: %w[chapters:write]),
          fiction_id: fictions(:eighteen).id,
          params: {
            number: 22, title: 'Великий', content: 'а' * 20_000,
            scanlator_ids: [scanlators(:two).id]
          }
        ).chapter
      end

      test 'version hashes content_html rather than ActionText to_s' do
        html = @chapter.content_html
        expected = Digest::SHA256.hexdigest("#{@chapter.title}\n#{html}")

        assert_equal expected, Serialize.version(@chapter)
        assert_equal expected, Serialize.full(@chapter)[:version]
      end

      test 'full can return only html' do
        only_html = Serialize.full(@chapter, body: :html)

        assert_predicate only_html[:html], :present?
        assert_nil only_html[:paragraphs]
      end

      test 'full can return only paragraphs' do
        only_paragraphs = Serialize.full(@chapter, body: :paragraphs)

        assert_nil only_paragraphs[:html]
        assert_predicate only_paragraphs[:paragraphs], :present?
      end
    end
  end
end
