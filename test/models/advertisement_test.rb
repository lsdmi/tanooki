# frozen_string_literal: true

require 'test_helper'

class AdvertisementTest < ActiveSupport::TestCase
  test 'should be valid' do
    advertisement = advertisements(:advertisement_one)
    assert advertisement.valid?
  end

  test 'should not be valid without caption' do
    advertisement = advertisements(:advertisement_one)
    advertisement.caption = nil
    assert_not advertisement.valid?
  end

  test 'should not be valid without resource' do
    advertisement = advertisements(:advertisement_one)
    advertisement.resource = nil
    assert_not advertisement.valid?
  end

  test 'should not be valid without cover' do
    advertisement = advertisements(:advertisement_one)
    advertisement.cover = nil
    assert_not advertisement.valid?
  end

  test 'should not be valid with caption length more than 50' do
    advertisement = advertisements(:advertisement_one)
    advertisement.caption = 'a' * 51
    assert_not advertisement.valid?
  end

  test 'should not be valid with resource length more than 300' do
    advertisement = advertisements(:advertisement_one)
    advertisement.resource = 'a' * 301
    assert_not advertisement.valid?
  end
end
