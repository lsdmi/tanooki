# frozen_string_literal: true

require 'test_helper'

class FictionLicenseTest < ActiveSupport::TestCase
  setup do
    @licensed = fictions(:one)
    @licensed.assign_attributes(licensed_at: 10.days.ago, license_publisher: 'Видавництво Тест',
                                license_url: 'https://publisher.example/book')
  end

  test 'search_data keeps a licensed work searchable and flags it' do
    data = @licensed.search_data

    assert data.fetch(:active)
    assert data.fetch(:licensed)
  end

  test 'licensed scopes split on licensed_at' do
    @licensed.save!(validate: false)

    assert_equal [@licensed], Fiction.licensed.to_a
    assert_not_includes Fiction.not_licensed, @licensed
    assert_includes Fiction.not_licensed, fictions(:two)
  end

  test 'a licensed stale work shows Ліцензовано while its listing state stays derived' do
    @licensed.assign_attributes(chapter_count: 3, last_chapter_at: 120.days.ago)

    assert_equal :stale, @licensed.listing_state
    assert_equal 'Ліцензовано', @licensed.public_listing_label
    assert_equal 'Ліценз.', @licensed.public_listing_label_short
  end

  test 'a licensed finished work keeps completed_at' do
    @licensed.assign_attributes(chapter_count: 5, last_chapter_at: 200.days.ago, completed_at: 150.days.ago)

    assert_predicate @licensed, :licensed?
    assert_equal :finished, @licensed.listing_state
    assert_equal 'Ліцензовано', @licensed.public_listing_label
  end

  test 'an unlicensed work falls back to the listing state label' do
    fiction = fictions(:two)

    assert_not fiction.licensed?
    assert_equal fiction.listing_state_label, fiction.public_listing_label
  end

  test 'a license needs a publisher or a URL' do
    @licensed.assign_attributes(license_publisher: ' ', license_url: '')
    @licensed.validate

    assert_nil @licensed.license_publisher
    assert_includes @licensed.errors.details[:license_publisher], { error: :source_missing }
  end

  test 'the license URL must be https' do
    @licensed.license_url = 'http://publisher.example/book'
    @licensed.validate

    assert_includes @licensed.errors.details[:license_url].pluck(:error), :invalid

    @licensed.license_url = 'https://publisher.example/book'
    @licensed.validate

    assert_empty @licensed.errors[:license_url]
  end

  test 'the publisher has a length limit' do
    @licensed.license_publisher = 'а' * 101
    @licensed.validate

    assert_includes @licensed.errors.details[:license_publisher].pluck(:error), :too_long
  end
end
