# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubDownloadPermissionTest < ActiveSupport::TestCase
    setup do
      @chapter = chapters(:one)
    end

    test 'a convertable chapter of an unlicensed fiction is allowed' do
      assert EpubDownloadPermission.allowed?([@chapter])
    end

    test 'a licensed fiction blocks the export with or without its fiction loaded' do
      fiction = @chapter.fiction
      fiction.scanlator_ids = fiction.scanlators.ids
      fiction.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест')

      assert_not EpubDownloadPermission.allowed?([Chapter.find(@chapter.id)])
      assert_not EpubDownloadPermission.allowed?([Chapter.includes(:fiction).find(@chapter.id)])
    end

    test 'nothing to export is not allowed' do
      assert_not EpubDownloadPermission.allowed?([])
    end
  end
end
