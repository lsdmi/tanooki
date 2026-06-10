# frozen_string_literal: true

require 'test_helper'

module Meta
  class PageTitleTest < ActiveSupport::TestCase
    include Rails.application.routes.url_helpers

    test 'resolve returns default title for unknown paths' do
      title = PageTitle.new(request_path: root_path).resolve

      assert_equal PageTitle::DEFAULT_TITLE, title
    end

    test 'resolve returns publication title' do
      publication = publications(:tale_approved_one)

      title = PageTitle.new(publication: publication).resolve

      assert_equal publication.title, title
    end

    test 'resolve returns search title on search index' do
      title = PageTitle.new(
        request_path: search_index_path,
        search_index_page: true,
        search_terms: ['test']
      ).resolve

      assert_equal 'test | Бака', title
    end

    test 'resolve returns static path copy for fictions index' do
      title = PageTitle.new(
        request_path: fictions_path,
        controller_name: 'fictions',
        action_name: 'index'
      ).resolve

      assert_equal I18n.t('meta.title.fictions.index'), title
    end

    test 'resolve returns genre title on genre show pages' do
      genre = genres(:one)

      title = PageTitle.new(genre: genre, genre_show_page: true).resolve

      assert_equal I18n.t('meta.title.genres.show', name: genre.name), title
    end
  end
end
