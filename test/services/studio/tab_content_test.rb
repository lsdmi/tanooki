# frozen_string_literal: true

require 'test_helper'

module Studio
  class TabContentTest < ActiveSupport::TestCase
    test 'call with pokemons tab assigns Pokemons::StudioTab' do
      user = users(:user_one)
      service = TabContent.new(user, 'pokemons', {})

      service.call

      assert_instance_of Pokemons::StudioTab, service.instance_variable_get(:@pokemon_show)
    end

    test 'call with blogs tab paginates publications' do
      user = users(:user_one)
      service = TabContent.new(user, 'blogs', { page: 1 })

      service.call

      assert_instance_of Pagy, service.instance_variable_get(:@pagy)

      assert_equal user.publications.order(created_at: :desc).limit(8).to_a,
                   service.instance_variable_get(:@publications).to_a
    end

    test 'call with bookshelves tab loads ordered bookshelves' do
      user = users(:user_one)
      service = TabContent.new(user, 'bookshelves', {})

      service.call

      assert_equal user.bookshelves.ordered.to_a, service.instance_variable_get(:@bookshelves).to_a
    end

    test 'call with profile tab loads avatars' do
      user = users(:user_one)
      service = TabContent.new(user, 'profile', {})

      service.call

      expected = Avatar.includes(:image_attachment).order(created_at: :desc)

      assert_equal expected.to_a, service.instance_variable_get(:@avatars).to_a
    end

    test 'call falls back to blogs when tab id is unknown' do
      user = users(:user_one)
      service = TabContent.new(user, 'not_a_real_tab', {})

      service.call

      assert_instance_of Pagy, service.instance_variable_get(:@pagy)
      assert_equal user.publications.order(created_at: :desc).limit(8).to_a,
                   service.instance_variable_get(:@publications).to_a
    end

    test 'blogs tab includes drafts' do
      user = users(:user_one)
      draft = publications(:tale_created_one)
      draft.update!(status: :draft)
      service = TabContent.new(user, 'blogs', { page: 1 })

      service.call

      assert_includes service.instance_variable_get(:@publications).to_a, draft
    end

    test 'blogs tab does not preload Action Text descriptions' do
      user = users(:user_one)
      service = TabContent.new(user, 'blogs', { page: 1 })

      service.call
      publications = service.instance_variable_get(:@publications).to_a

      assert_queries_count(0) do
        publications.each(&:excerpt)
      end
      publications.each do |publication|
        assert_not publication.association(:rich_text_description).loaded?
      end
    end

    test 'writings tab assigns open paragraph report counts by fiction' do
      fiction = fictions(:one)
      ParagraphReport.create!(
        user: users(:user_two),
        chapter: chapters(:one),
        block_index: 0,
        quote: 'Цитата',
        digest: 'c' * ParagraphReport::DIGEST_LENGTH
      )
      ParagraphReport.create!(
        user: users('user_101'),
        chapter: chapters(:two),
        block_index: 0,
        quote: 'Інша',
        digest: 'd' * ParagraphReport::DIGEST_LENGTH,
        status: :fixed,
        resolved_at: Time.current
      )
      service = TabContent.new(users(:user_one), 'writings', { page: 1 })

      service.call
      counts = service.instance_variable_get(:@fiction_open_report_counts)

      assert_equal 1, counts[fiction.id]
      assert_nil counts[fictions(:two).id]
    end

    test 'current_digests_for preloads chapter rich text' do
      chapters = [chapters(:one), chapters(:two)]
      service = TabContent.new(users(:user_one), 'notifications', {})

      digests = service.send(:current_digests_for, chapters)

      assert_equal chapters.map(&:id).sort, digests.keys.sort
      chapters.each { |chapter| assert_predicate chapter.association(:rich_text_content), :loaded? }
      assert_queries_count(0) do
        chapters.each { |chapter| Chapters::ReaderContentHtml.new(chapter).digest }
      end
    end
  end
end
