# frozen_string_literal: true

require 'test_helper'

class ContestsHelperTest < ActionView::TestCase
  include ContestsHelper

  test 'requirements line lists kind deadline and volume' do
    contest = contests(:submissions)
    line = contest_submit_requirements_line(contest)

    assert_match(/ориджинал/i, line)
    assert_match(/3/, line)
  end

  test 'gallery column count fills a row then folds evenly' do
    expected = { 5 => 5, 6 => 3, 7 => 4, 8 => 4, 9 => 3, 10 => 5, 12 => 4, 15 => 5, 16 => 6 }

    assert_equal(expected, expected.keys.index_with { |count| contest_gallery_column_count(count) })
  end

  test 'gallery grid class keeps three-across on phones for three-plus cards' do
    classes = [3, 4, 5].map { |count| contest_gallery_grid_class(count) }

    assert(classes.all? { |css| css.include?('grid-cols-3') && css.exclude?('grid-cols-2') })
  end

  test 'gallery grid class applies sm column count' do
    assert_includes contest_gallery_grid_class(5), 'sm:grid-cols-5'
    assert_includes contest_gallery_grid_class(6), 'sm:grid-cols-3'
  end

  test 'gallery grid class opens six cards to a full row from xl' do
    assert_includes contest_gallery_grid_class(6), 'xl:grid-cols-6'
    assert_not_includes contest_gallery_grid_class(5), 'xl:grid-cols-6'
  end

  test 'archive dates line folds months and results day' do
    contest = contests(:results)
    line = contest_archive_dates_line(contest)

    assert_match(/· підсумки \d{1,2} [а-яїєґ]+ \d{4} р\./, line)
    assert_no_match(/Березень|Січень|Лютий/, line)
  end
end
