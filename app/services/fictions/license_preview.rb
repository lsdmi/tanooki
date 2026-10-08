# frozen_string_literal: true

module Fictions
  # What stays readable after a rights holder takedown: the first LIMIT released chapters in list order
  # (one chapter translated by two teams counts once), and the range hidden past them.
  class LicensePreview
    LIMIT = 6

    def initialize(fiction)
      @fiction = fiction
    end

    def chapter_ids
      keys = preview_keys.to_set
      released_rows.select { |row| keys.include?(key(row)) }.map(&:id)
    end

    def available_count
      preview_keys.size
    end

    def released_count
      released_keys.size
    end

    def hidden_count
      released_count - available_count
    end

    def available_range
      number_range(preview_keys)
    end

    def hidden_range
      number_range(hidden_keys)
    end

    def hidden_number?(number)
      hidden_keys.any? { |chapter_number, _volume| chapter_number == number }
    end

    private

    def released_rows
      @released_rows ||= @fiction.chapters.released.order(Library::ChapterCatalog.order_clause)
                                 .select(:id, :number, :volume_number).to_a
    end

    def released_keys
      @released_keys ||= released_rows.map { |row| key(row) }.uniq
    end

    def preview_keys
      released_keys.first(LIMIT)
    end

    def hidden_keys
      released_keys.drop(LIMIT)
    end

    def key(row)
      [row.number, row.volume_number]
    end

    def number_range(keys)
      return if keys.empty?

      first, last = [keys.first, keys.last].map { |number, _volume| Chapters::Formatting.format_decimal(number).to_s }
      first == last ? first : "#{first}–#{last}"
    end
  end
end
