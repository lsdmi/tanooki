# frozen_string_literal: true

require 'test_helper'

module Chapters
  class PurgeOrphanImagesJobTest < ActiveSupport::TestCase
    setup do
      @old_orphan = travel_to(8.days.ago) { store_chapter_image('image bytes') }
      @recent_orphan = travel_to(1.day.ago) { store_chapter_image('image bytes') }
      @old_attached = travel_to(30.days.ago) { store_chapter_image('image bytes') }
      chapters(:one).images_attachments.create!(blob: @old_attached)
      @old_cover = travel_to(30.days.ago) do
        ActiveStorage::Blob.create_and_upload!(io: StringIO.new('x'), filename: 'c.webp', service_name: 'test')
      end
    end

    test 'purges only unattached chapter images past the grace period' do
      PurgeOrphanImagesJob.perform_now

      assert purged?(@old_orphan)
      assert_equal([false, false, false], [@recent_orphan, @old_attached, @old_cover].map { purged?(it) })
    end

    test 'deletes the file and the row, not only a soft delete' do
      service = ActiveStorage::Blob.services.fetch(@old_orphan.service_name)

      PurgeOrphanImagesJob.perform_now

      assert_not service.exist?(@old_orphan.key)
      assert_not ActiveStorage::Blob.with_deleted.exists?(@old_orphan.id)
    end

    test 'finishes rows an earlier purge only soft-deleted' do
      @old_orphan.destroy!

      PurgeOrphanImagesJob.perform_now

      assert_not ActiveStorage::Blob.with_deleted.exists?(@old_orphan.id)
    end

    test 'keeps the images of a soft-deleted chapter and purges them once it is hard-deleted' do
      chapters(:one).destroy!
      PurgeOrphanImagesJob.perform_now

      assert_not purged?(@old_attached)

      Chapter.with_deleted.find(chapters(:one).id).really_destroy!
      PurgeOrphanImagesJob.perform_now

      assert purged?(@old_attached)
    end

    private

    def purged?(blob)
      !ActiveStorage::Blob.with_deleted.exists?(blob.id)
    end
  end
end
