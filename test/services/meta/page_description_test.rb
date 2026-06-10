# frozen_string_literal: true

require 'test_helper'

module Meta
  class PageDescriptionTest < ActiveSupport::TestCase
    include Rails.application.routes.url_helpers

    test 'resolve returns default description for unknown paths' do
      description = PageDescription.new(request_path: root_path).resolve

      assert_equal PageDescription::DEFAULT_DESCRIPTION, description
    end

    test 'resolve returns first publication sentence' do
      publication = publications(:tale_approved_one)
      expected = publication.description.to_plain_text.split(/(?<=[.?!])\s+/).first

      description = PageDescription.new(publication: publication).resolve

      assert_equal expected, description
    end

    test 'resolve returns fiction description without scanlators' do
      fiction = fictions(:one)
      fiction.scanlators.clear

      description = PageDescription.new(fiction: fiction).resolve

      assert_equal "Читати ранобе \"#{fiction.title}\" за авторства \"#{fiction.author}\".", description
    end

    test 'static_path? matches configured index routes' do
      assert PageDescription.static_path?(fictions_path)
      assert_not PageDescription.static_path?(root_path)
    end

    test 'resolve returns static path copy for fictions index' do
      description = PageDescription.new(
        request_path: fictions_path,
        controller_name: 'fictions',
        action_name: 'index'
      ).resolve

      assert_equal I18n.t('meta.description.fictions.index'), description
    end

    test 'resolve returns genre description on genre show pages' do
      genre = genres(:one)

      description = PageDescription.new(genre: genre, genre_show_page: true).resolve

      assert_equal I18n.t('meta.description.genres.show', name: genre.name, count: genre.fictions.count), description
    end
  end
end
