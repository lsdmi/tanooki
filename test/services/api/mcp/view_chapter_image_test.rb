# frozen_string_literal: true

require 'test_helper'

module Api
  module Mcp
    class ViewChapterImageTest < ActiveSupport::TestCase
      setup do
        @user = users(:user_two)
        @fiction = fictions(:eighteen)
        FictionScanlator.find_or_create_by!(fiction: @fiction, scanlator: scanlators(:two))
        @token = ApiToken.issue!(user: @user, name: 'Claude', scopes: %w[chapters:read chapters:write])
        @context = { user: @user, token: @token }
      end

      teardown { Rails.cache.delete(Api::Limits.counter_key(:create, @user, Date.current)) }

      test 'returns one still of an image that is already in the chapter' do
        response = Tools::ViewChapterImage.call(server_context: @context, chapter_id: chapter_with_image.id, index: 1)
        body = JSON.parse(response.content.first['text'])
        image = response.content.second

        assert_equal 'image', image['type']
        assert_equal 'image/webp', image['mimeType']
        assert_not body['animated']
      end

      test 'needs an address or an index' do
        result = Tools::ViewChapterImage.call(server_context: @context, chapter_id: chapter_with_image.id)

        assert_predicate result, :error?
        assert_equal 'invalid', JSON.parse(result.content.first['text']).dig('error', 'code')
      end

      test 'refuses an address that is not in the chapter' do
        result = Tools::ViewChapterImage.call(
          server_context: @context, chapter_id: chapter_with_image.id, url: 'https://example.com/a.png'
        )

        assert_predicate result, :error?
        assert_equal 'image_not_in_chapter', JSON.parse(result.content.first['text']).dig('error', 'code')
      end

      test 'another teams chapter is not found' do
        result = Tools::ViewChapterImage.call(server_context: @context, chapter_id: chapters(:one).id, index: 1)

        assert_predicate result, :error?
        assert_equal 'not_found', JSON.parse(result.content.first['text']).dig('error', 'code')
      end

      test 'viewing an image counts as a read' do
        raw = { method: 'tools/call', params: { name: 'view_chapter_image' } }.to_json

        assert Api::Mcp::RequestKind.read?(raw)
      end

      private

      def chapter_with_image
        @chapter_with_image ||= attach_image(create_chapter)
      end

      def create_chapter
        Chapters::Create.call(
          user: @user, token: @token, fiction_id: @fiction.id,
          params: { number: 9914, title: 'Картинка', content: 'Абзац для картинки.' }
        ).chapter
      end

      def attach_image(chapter)
        url = ::Chapters::Images.url_for(store_chapter_image)
        chapter.update!(content: %(<p>Абзац для картинки.</p><img src="#{url}" alt="кадр">))
        chapter
      end
    end
  end
end
