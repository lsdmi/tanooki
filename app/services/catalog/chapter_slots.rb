# frozen_string_literal: true

module Catalog
  # Distinct catalog chapter slots: (number, volume), matching chapters a reader can open.
  # 1, 2, 3.1, 3.2 → 4. Том 1 розд. 1 and том 2 розд. 1 → 2.
  # Two teams on the same volume+number count once. Soft-deleted rows are out.
  # A chapter on a timer counts once it is public. Drafts do not.
  class ChapterSlots
    def self.call(fiction)
      new(fiction).call
    end

    def initialize(fiction)
      @fiction = fiction
    end

    def call
      @fiction.chapters.released.pluck(:number, :volume_number).uniq.size
    end
  end
end
