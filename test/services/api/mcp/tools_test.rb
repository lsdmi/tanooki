# frozen_string_literal: true

require 'test_helper'

module Api
  module Mcp
    class ToolsTest < ActiveSupport::TestCase
      setup do
        @user = users(:user_two)
        @fiction = fictions(:eighteen)
        FictionScanlator.find_or_create_by!(fiction: @fiction, scanlator: scanlators(:two))
      end

      teardown { Rails.cache.delete(Api::Limits.counter_key(:create, @user, Date.current)) }

      test 'read tools refuse a token without chapters read' do
        context = actor(%w[images:write])
        refused = [Tools::ListMyFictions, Tools::ListChapters, Tools::GetChapter, Tools::GetChapters, Tools::ChapterDiff]

        refused.each { |tool| assert_predicate call(tool, read_args(tool), context), :error? }
      end

      test 'write tools refuse a read only token' do
        context = actor(%w[chapters:read])
        refused = [
          Tools::CreateChapter, Tools::EditParagraphs, Tools::UpdateChapter, Tools::RevertChapter,
          Tools::PublishChapter, Tools::UploadImageFromUrl
        ]

        refused.each { |tool| assert_predicate call(tool, write_args(tool), context), :error? }
      end

      test 'whoami works for any token and lists the user' do
        body = json(call(Tools::Whoami, {}, actor(%w[images:write])))

        assert_equal @user.id, body.dig('user', 'id')
      end

      test 'a draft can be edited and reverted' do
        context = actor(%w[chapters:read chapters:write chapters:publish])
        created = json(call(Tools::CreateChapter, draft(8802, 'Було слово.'), context))
        edited = json(call(Tools::EditParagraphs, edit_args(created), context))
        reverted = json(call(Tools::RevertChapter, revert_args(created['id']), context))

        assert_equal 'mcp', Chapter.find(created['id']).created_via
        assert_equal 'paragraphs', edited.dig('diff', 'summary')
        assert_equal 'reverted', reverted.dig('diff', 'summary')
      end

      test 'publishing needs the publish scope' do
        context = actor(%w[chapters:read chapters:write])
        created = json(call(Tools::CreateChapter, draft(8803, 'Чернетка.'), context))
        result = call(Tools::PublishChapter, { chapter: created['id'], version: created['version'] }, context)

        assert_predicate result, :error?
        assert_equal 'publish_scope', json(result).dig('error', 'code')
      end

      private

      def actor(scopes)
        token = ApiToken.issue!(user: @user, name: 'Claude', scopes:)
        { user: @user, token: }
      end

      def call(tool, args, context)
        tool.call(**args, server_context: context)
      end

      def json(response)
        JSON.parse(response.content.first['text'])
      end

      def read_args(tool)
        case tool.tool_name
        when 'list_my_fictions' then {}
        when 'list_chapters', 'get_chapters' then { fiction: @fiction.slug, from: 1, to: 2 }
        when 'get_chapter' then { chapter_id: chapters(:one).id }
        else { chapter: chapters(:one).id }
        end
      end

      def write_args(tool)
        case tool.tool_name
        when 'create_chapter' then { fiction: @fiction.slug, number: 1, content: 'x' }
        when 'edit_paragraphs' then { chapter: 1, version: 'v', edits: [{ n: 1, old: 'a', new: 'b' }] }
        when 'update_chapter' then { chapter: 1, version: 'v', title: 'Інша' }
        when 'revert_chapter' then { chapter: 1, revision: 1 }
        when 'publish_chapter' then { chapter: 1, version: 'v' }
        else { url: 'https://cdn.example/a.webp' }
        end
      end

      def draft(number, content)
        { fiction: @fiction.slug, number:, content: }
      end

      def edit_args(created)
        paragraph = created['paragraphs'].first
        {
          chapter: created['id'], version: created['version'],
          edits: [{ n: paragraph['n'], old: paragraph['markdown'], new: 'Стало слово.' }]
        }
      end

      def revert_args(chapter_id)
        { chapter: chapter_id, revision: revision_id(chapter_id) }
      end

      def revision_id(chapter_id)
        Chapter.find(chapter_id).revisions.order(created_at: :desc, id: :desc).first.id
      end
    end
  end
end
