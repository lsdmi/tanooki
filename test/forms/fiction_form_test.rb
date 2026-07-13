# frozen_string_literal: true

require 'test_helper'

class FictionFormTest < ActiveSupport::TestCase
  test 'keeps scanlator_ids and genre_ids from params when save fails' do
    fiction = fictions(:one)
    submitted_scanlator_ids = %w[1 2]
    submitted_genre_ids = [genres(:one).id]

    form = FictionForm.new(
      fiction: fiction,
      params: {
        title: '',
        author: fiction.author,
        description: fiction.description,
        total_chapters: fiction.total_chapters,
        scanlator_ids: submitted_scanlator_ids,
        genre_ids: submitted_genre_ids
      }
    )

    assert_not form.save
    assert_equal submitted_scanlator_ids, fiction.scanlator_ids.map(&:to_s)
    assert_equal submitted_genre_ids.map(&:to_s), fiction.genre_ids.map(&:to_s)
  end

  test 'rejects invalid cover upload' do
    fiction = fictions(:one)
    form = FictionForm.new(
      fiction: fiction,
      params: {
        title: fiction.title,
        author: fiction.author,
        description: fiction.description,
        total_chapters: fiction.total_chapters,
        scanlator_ids: [1],
        cover: Rack::Test::UploadedFile.new(
          Rails.root.join('app/assets/images/logo-default.svg'),
          'image/svg'
        )
      }
    )

    assert_not form.save
    assert_includes fiction.errors[:cover], 'Обкладинка має бути WebP, AVIF, JPEG або PNG.'
  end

  test 'accepts valid cover upload' do
    fiction = fictions(:one)
    form = FictionForm.new(
      fiction: fiction,
      params: {
        title: fiction.title,
        author: fiction.author,
        description: fiction.description,
        total_chapters: fiction.total_chapters,
        scanlator_ids: [1],
        cover: valid_cover_upload
      }
    )

    assert form.save
  end

  test 'converts png upload to webp before save' do
    skip 'libvips not installed' unless Attachments::VariantProcessing.available?

    fiction = fictions(:one)
    form = FictionForm.new(
      fiction: fiction,
      params: {
        title: fiction.title,
        author: fiction.author,
        description: fiction.description,
        total_chapters: fiction.total_chapters,
        scanlator_ids: [1],
        cover: valid_png_cover_upload
      }
    )

    assert form.save
    assert_equal 'image/webp', fiction.cover.blob.content_type
  end

  test 'allows update without cover param for legacy attachment' do
    fiction = fictions(:one)
    form = FictionForm.new(
      fiction: fiction,
      params: {
        title: 'Legacy Cover Still Fine',
        author: fiction.author,
        description: fiction.description,
        total_chapters: fiction.total_chapters,
        scanlator_ids: [1]
      }
    )

    assert form.save
    assert_equal 'Legacy Cover Still Fine', fiction.reload.title
  end
end
