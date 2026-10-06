# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ReaderBottomHelperTest < ActionView::TestCase
    include ReaderBottomHelper

    test 'fiction_reader_support? is true when a scanlator has bank url' do
      fiction = fictions(:one)
      fiction.scanlators.first.update!(bank_url: 'https://send.monobank.ua/jar/example')

      assert fiction_reader_support?(fiction)
    end

    test 'fiction_reader_support? is false without bank url' do
      fiction = fictions(:one)
      fiction.scanlators.each { |scanlator| scanlator.update!(bank_url: nil) }

      assert_not fiction_reader_support?(fiction)
    end

    test 'fiction_reader_support? is false for a saved link that is not on a donation service' do
      fiction = fictions(:one)
      fiction.scanlators.each do |scanlator|
        scanlator.bank_url = 'https://t.me/c/1614732671/498'
        scanlator.save!(validate: false)
      end

      assert_not fiction_reader_support?(fiction)
    end

    test 'fiction_reader_support_url normalizes bank url' do
      fiction = fictions(:one)
      fiction.scanlators.first.update!(bank_url: 'send.monobank.ua/jar/example')

      assert_equal 'https://send.monobank.ua/jar/example', fiction_reader_support_url(fiction)
    end

    test 'fiction_reader_support_label names the donation service' do
      fiction = fictions(:one)
      fiction.scanlators.first.update!(bank_url: 'https://donatello.to/team')

      assert_equal 'Підтримати через Donatello', fiction_reader_support_label(fiction)
    end
  end
end
