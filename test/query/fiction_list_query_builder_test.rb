# frozen_string_literal: true

require 'test_helper'

class FictionListQueryBuilderTest < ActiveSupport::TestCase
  setup do
    @finished = fictions(:one)
    @open = fictions(:two)
    @finished.scanlator_ids = @finished.scanlators.ids
    @open.scanlator_ids = @open.scanlators.ids
    @finished.update!(completed_at: Time.current)
    @open.update!(completed_at: nil)
  end

  test 'finished filter uses completed_at not chapter recency' do
    @finished.update!(last_chapter_at: 1.day.ago, chapter_count: 3)
    @open.update!(last_chapter_at: 1.day.ago, chapter_count: 3)

    ids = FictionListQueryBuilder.new(Fiction.all, finished: '1').call.map(&:id)

    assert_includes ids, @finished.id
    assert_not_includes ids, @open.id
  end

  test 'licensed filter keeps only licensed works' do
    @open.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест')

    ids = FictionListQueryBuilder.new(Fiction.all, licensed: '1').call.map(&:id)

    assert_equal [@open.id], ids
  end

  test 'query matches title and author and ignores a single character' do
    @open.update!(title: 'Павучиха з архіву', author: 'Авторка Тест')

    ids = FictionListQueryBuilder.new(Fiction.all, q: 'павуч').call.map(&:id)

    assert_includes ids, @open.id

    author_ids = FictionListQueryBuilder.new(Fiction.all, q: 'авторка').call.map(&:id)

    assert_includes author_ids, @open.id

    assert_includes FictionListQueryBuilder.new(Fiction.all, q: 'п').call.map(&:id), @finished.id
  end

  test 'without finished filter both listings remain' do
    ids = FictionListQueryBuilder.new(Fiction.all, {}).call.map(&:id)

    assert_includes ids, @finished.id
    assert_includes ids, @open.id
  end

  test 'title_asc is the default sort and orders by title' do
    @finished.update!(title: 'Бета')
    @open.update!(title: 'Альфа')

    ids = FictionListQueryBuilder.new(Fiction.all, {}).call.map(&:id)

    assert_operator ids.index(@open.id), :<, ids.index(@finished.id)
    assert_equal 'title_asc', FictionListQueryBuilder.normalize_sort(nil)
  end

  test 'title_desc reverses the alphabet' do
    @finished.update!(title: 'Бета')
    @open.update!(title: 'Альфа')

    ids = FictionListQueryBuilder.new(Fiction.all, sort: 'title_desc').call.map(&:id)

    assert_operator ids.index(@finished.id), :<, ids.index(@open.id)
  end

  test 'title_asc places latin letters with matching cyrillic peers' do
    latin = @open
    before = @finished
    after = fictions(:eighteen)
    after.scanlator_ids = after.scanlators.ids.presence || @open.scanlator_ids
    before.update!(title: 'Поле')
    latin.update!(title: 'Re: Життя в іншому світі з нуля')
    after.update!(title: 'Сон')

    ids = FictionListQueryBuilder.new(Fiction.all, sort: 'title_asc').call.map(&:id)

    assert_operator ids.index(before.id), :<, ids.index(latin.id)
    assert_operator ids.index(latin.id), :<, ids.index(after.id)
  end

  test 'updated_desc orders by the latest released chapter' do
    set_chapter_public_time(chapters(:one), 5.days.ago)
    set_chapter_public_time(chapters(:two), 5.days.ago)
    set_chapter_public_time(chapters(:three), 1.day.ago)

    ids = FictionListQueryBuilder.new(Fiction.all, sort: 'updated_desc').call.map(&:id)

    assert_operator ids.index(@open.id), :<, ids.index(@finished.id)
  end

  test 'popular_desc orders by reading progress count' do
    ReadingProgress.where(fiction_id: [@finished.id, @open.id]).delete_all
    chapter = chapters(:three)
    ReadingProgress.create!(user: users(:user_one), fiction: @open, chapter: chapter)
    ReadingProgress.create!(user: users(:user_two), fiction: @open, chapter: chapter)

    ids = FictionListQueryBuilder.new(Fiction.all, sort: 'popular_desc').call.map(&:id)

    assert_operator ids.index(@open.id), :<, ids.index(@finished.id)
  end

  test 'rating_desc orders by average rating' do
    FictionRating.where(fiction_id: [@finished.id, @open.id]).delete_all
    FictionRating.create!(user: users(:user_one), fiction: @open, rating: 5)
    FictionRating.create!(user: users(:user_two), fiction: @finished, rating: 2)

    ids = FictionListQueryBuilder.new(Fiction.all, sort: 'rating_desc').call.map(&:id)

    assert_operator ids.index(@open.id), :<, ids.index(@finished.id)
  end

  test 'genre filter keeps every genre on the matched works' do
    FictionGenre.create!(fiction: @finished, genre: genres(:two))

    results = FictionListQueryBuilder.new(Fiction.all, genre: genres(:one).id).call.to_a
    matched = results.find { |fiction| fiction.id == @finished.id }

    assert matched
    assert_equal ['Жанр Альфа', 'Жанр Бета'], matched.genres.map(&:name).sort
  end

  private

  def set_chapter_public_time(chapter, time)
    attrs = {
      created_at: time,
      published_at: nil,
      status: 'published',
      scanlator_ids: chapter.scanlators.ids.presence || [scanlators(:one).id]
    }
    attrs[:content] = ('a' * 500) if chapter.content.blank? ||
                                     chapter.content.body.to_plain_text.length < 500
    chapter.update!(attrs)
  end
end
