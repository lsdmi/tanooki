# frozen_string_literal: true

module FictionTags
  # Folds a duplicate tag into the surviving one: moves its links, drops pairs the target already has,
  # then deletes the source. One transaction. Link rows move one by one so the fictions_count counter
  # cache stays right.
  # An explicit source makes the target explicit, so merged works never lose their 18+ marking.
  # Every work that carried the source is refreshed after commit, including those that already had the target:
  # the source name leaves their page and their search entry.
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
      fiction_ids = @source.fiction_tag_links.pluck(:fiction_id)

      result = FictionTag.transaction do
        moved = move_links
        @target.update!(explicit: true) if @source.explicit? && !@target.explicit?
        @source.reload.destroy!
        moved
      end
      RefreshFictions.call(fiction_ids)
      result
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
      Result.new(moved: moving.size, skipped:)
    end
  end
end
