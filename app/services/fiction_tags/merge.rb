# frozen_string_literal: true

module FictionTags
  # Folds a duplicate tag into the surviving one: moves its links, drops pairs the target already has,
  # then deletes the source. One transaction. Link rows move one by one so the fictions_count counter
  # cache stays right.
  # An explicit source makes the target explicit, so merged works never lose their 18+ marking.
  # Saving each moved fiction expires fragments keyed on it and queues a Searchkick reindex.
  class Merge
    Result = Data.define(:moved, :skipped)

    def self.call(source:, target:)
      new(source:, target:).call
    end

    def initialize(source:, target:)
      @source = source
      @target = target
    end

    def call
      check_arguments!

      FictionTag.transaction do
        result = move_links
        @target.update!(explicit: true) if @source.explicit? && !@target.explicit?
        @source.reload.destroy!
        result
      end
    end

    private

    def check_arguments!
      raise ArgumentError, 'source and target must differ' if @source.id == @target.id
      raise ArgumentError, 'target is hidden' if @target.hidden?
    end

    def move_links
      shared_ids = @target.fiction_tag_links.pluck(:fiction_id)
      skipped = @source.fiction_tag_links.where(fiction_id: shared_ids).destroy_all.size
      moving = @source.fiction_tag_links.where.not(fiction_id: shared_ids).to_a
      moving.each { |link| link.update!(fiction_tag: @target) }
      refresh_fictions(moving.map(&:fiction_id))
      Result.new(moved: moving.size, skipped:)
    end

    def refresh_fictions(fiction_ids)
      Fiction.where(id: fiction_ids).find_each do |fiction|
        fiction.updated_at = Time.current
        fiction.save!(validate: false)
      end
    end
  end
end
