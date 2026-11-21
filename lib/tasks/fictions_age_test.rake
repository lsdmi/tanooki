# frozen_string_literal: true

# Dev-only test data for the 16+ / 18+ age marks. Slugs start with `age-test-` so they can be cleared together.
module FictionsAgeTest
  RATINGS = { 'sixteen' => '16', 'eighteen' => '18' }.freeze
  SLUG_PREFIX = 'age-test-'

  module_function

  def seed(count)
    pool = {
      covers: reusable_cover_blobs,
      scanlator_ids: Scanlator.joins(:fiction_scanlators).distinct.limit(50).pluck(:id)
    }
    abort 'no existing covers or scanlators to reuse' if pool[:covers].empty? || pool[:scanlator_ids].empty?

    RATINGS.each_with_index.sum do |(rating, label), rating_index|
      seed_rating(rating:, label:, count:, pool:, offset: rating_index * count)
    end
  end

  def seed_rating(rating:, label:, count:, pool:, offset:)
    created = 0
    count.times do |index|
      next if Fiction.unscoped.exists?(slug: slug_for(label, index + 1))

      create_fiction(rating:, label:, number: index + 1,
                     cover: pool[:covers][(offset + index) % pool[:covers].size],
                     scanlator_id: pool[:scanlator_ids].sample.to_s)
      created += 1
    end
    created
  end

  def clear
    scope = Fiction.unscoped.where('slug LIKE ?', "#{SLUG_PREFIX}%")
    ids = scope.ids
    # Detach without purging: the cover blob is shared with the real fictions.
    ActiveStorage::Attachment.where(record_type: 'Fiction', record_id: ids, name: 'cover').delete_all
    scope.find_each(&:really_destroy!)
    ids.size
  end

  # Reuse existing WebP/AVIF cover blobs (the validator requires them). The test fictions never own these blobs.
  def reusable_cover_blobs
    ActiveStorage::Attachment.where(record_type: 'Fiction', name: 'cover')
                             .joins(:blob)
                             .where(active_storage_blobs: { content_type: %w[image/webp image/avif] })
                             .limit(300).map(&:blob)
  end

  def slug_for(label, number)
    "#{SLUG_PREFIX}#{label}-#{format('%02d', number)}"
  end

  def create_fiction(rating:, label:, number:, cover:, scanlator_id:)
    genre_ids = Genre.order(Arel.sql('RAND()')).limit(2).ids.map(&:to_s)
    fiction = build_fiction(rating:, label:, number:, genre_ids:, scanlator_id:)
    fiction.cover.attach(cover)
    save_with_associations(fiction, genre_ids:, scanlator_id:)
  end

  def build_fiction(rating:, label:, number:, genre_ids:, scanlator_id:)
    Fiction.new(
      slug: slug_for(label, number),
      title: "Тест #{label}+ №#{format('%02d', number)}",
      author: 'Тест Автор',
      description: "Тестовий твір з віковою міткою #{label}+ для перевірки обкладинок і фільтрів.",
      content_rating: rating,
      genre_ids:,
      scanlator_ids: [scanlator_id]
    )
  end

  def save_with_associations(fiction, genre_ids:, scanlator_id:)
    fiction.save!
    Fictions::SyncAssociations.new(fiction, genre_ids:, scanlator_ids: [scanlator_id]).call
  rescue StandardError
    # Remove a half-built fiction; the shared cover blob is detached, never purged.
    discard_fiction(fiction) if fiction.persisted?
    raise
  end

  def discard_fiction(fiction)
    ActiveStorage::Attachment.where(record_type: 'Fiction', record_id: fiction.id, name: 'cover').delete_all
    fiction.really_destroy!
  end
end

desc 'Dev only: seed COUNT (default 12) fictions per rating (16+, 18+). Slugs start with age-test-'
task 'fictions:seed_age_test': :environment do
  abort 'fictions:seed_age_test runs in development only' unless Rails.env.development?

  count = Integer(ENV.fetch('COUNT', 12))
  created = FictionsAgeTest.seed(count)

  puts "Created #{created} fictions (#{count} per rating). Clear with: bin/rails fictions:clear_age_test"
end

desc 'Dev only: remove fictions created by fictions:seed_age_test (keeps the shared cover blobs)'
task 'fictions:clear_age_test': :environment do
  abort 'fictions:clear_age_test runs in development only' unless Rails.env.development?

  puts "Removed #{FictionsAgeTest.clear} age-test fictions."
end
