# frozen_string_literal: true

require 'test_helper'

module Meta
  class BookshelvesHubHelperTest < ActionView::TestCase
    include Rails.application.routes.url_helpers
    include ApplicationHelper
    include Meta::TagsHelper

    test 'bookshelves hub resolves title description and cover from popular' do
      request.path = bookshelves_path
      define_singleton_method(:controller_name) { 'bookshelves' }
      define_singleton_method(:action_name) { 'index' }
      fiction = Struct.new(:cover, keyword_init: true).new(cover: '/covers/hub-focus.webp')
      entry = Struct.new(:covers, keyword_init: true).new(covers: [fiction])
      @popular = [entry]

      assert_equal I18n.t('meta.title.bookshelves.index'), meta_title
      assert_equal I18n.t('meta.description.bookshelves.index'), meta_description
      assert_equal 'http://example.com/covers/hub-focus.webp', meta_image
    end
  end
end
