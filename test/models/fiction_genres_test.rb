# frozen_string_literal: true

require 'test_helper'

class FictionGenresTest < ActiveSupport::TestCase
  def setup
    @fiction = fictions(:one)
    @genre = genres(:one)
    @fiction_genre = fiction_genres(:one)
  end

  test 'should be valid' do
    assert @fiction_genre.valid?
  end

  test 'should require fiction' do
    @fiction_genre.fiction = nil
    assert_not @fiction_genre.valid?
  end

  test 'should require genre' do
    @fiction_genre.genre = nil
    assert_not @fiction_genre.valid?
  end

  test 'should belong to fiction' do
    assert_equal @fiction, @fiction_genre.fiction
  end

  test 'should belong to genre' do
    assert_equal @genre, @fiction_genre.genre
  end
end
