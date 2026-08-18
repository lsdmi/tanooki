# frozen_string_literal: true

namespace :books do
  desc 'Destroy expired EPUB export requests and attached files (CI / laptop)'
  task purge_expired_epub_exports: :environment do
    result = Books::PurgeExpiredEpubExports.call

    puts "purged=#{result.purged} errors=#{result.errors.size}"
    result.errors.each { |error| puts "  export=#{error[:export_id]} #{error[:error]}" }

    abort 'books:purge_expired_epub_exports failed' if result.errors.any?
  end
end
