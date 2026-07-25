# frozen_string_literal: true

require 'test_helper'

class SiteFriendTest < ActiveSupport::TestCase
  test 'all entries have required fields and valid section' do
    section_ids = SiteFriend::SECTIONS.map(&:id)

    invalid = SiteFriend.all.reject do |friend|
      friend.name.present? && friend.url.match?(%r{\Ahttps?://}) && section_ids.include?(friend.section)
    end

    assert_empty invalid
  end

  test 'urls are unique' do
    urls = SiteFriend.all.map(&:url)

    assert_equal urls.uniq.size, urls.size
  end

  test 'sections include every friend' do
    grouped = SiteFriend.sections.flat_map { |group| group[:friends] }

    assert_equal SiteFriend.all.size, grouped.size
  end

  test 'sections preserve friend urls' do
    grouped = SiteFriend.sections.flat_map { |group| group[:friends] }

    assert_equal SiteFriend.all.map(&:url).sort, grouped.map(&:url).sort
  end

  test 'sections use expected titles' do
    titles = SiteFriend.sections.map { |group| group[:section].title }

    assert_equal %w[Перегляд Манґа Аніме Підтримка], titles
  end
end
