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

      assert_not ActiveStorage::Blob.exists?(@old_orphan.id)
      assert_equal [@recent_orphan, @old_attached, @old_cover].map(&:id).sort,
                   ActiveStorage::Blob.where(id: [@recent_orphan, @old_attached, @old_cover]).ids.sort
    end
  end
end
