# frozen_string_literal: true

module Books
  # Daily CI / operator pass: destroy expired EPUB export requests and attached files.
  class PurgeExpiredEpubExports
    Result = Data.define(:purged, :errors)

    def self.call
      new.call
    end

    def call
      tallies = { purged: 0, errors: [] }
      EpubExportRequest.expired.find_each { |export| purge_one!(tallies, export) }
      Result.new(**tallies)
    end

    private

    def purge_one!(tallies, export)
      export.destroy!
      tallies[:purged] += 1
    rescue StandardError => e
      Rails.logger.error("[PurgeExpiredEpubExports] id=#{export.id} #{e.class}: #{e.message}")
      tallies[:errors] << { export_id: export.id, error: "#{e.class}: #{e.message}" }
    end
  end
end
