# frozen_string_literal: true

module Fictions
  # Loads chapters for one fiction TOC accordion section (volume or numeric range).
  class ChapterSectionLoader
    # The fiction page shows a group a page at a time; the reader drawer always gets the whole group.
    PAGE_SIZE = 20
    MOBILE_PAGE_SIZE = 10

    def initialize(fiction:, viewer:, section_key:, order:, chapter_ids: nil)
      @fiction = fiction
      @viewer = viewer
      @section_key = section_key.to_s
      @order = order
      @chapter_ids = parse_chapter_ids(chapter_ids)
    end

    def call(offset: 0, limit: nil)
      scope.includes(:scanlators).reorder(list_order_sql).offset(offset.to_i.clamp(0..).nonzero?).limit(limit)
    end

    def total
      scope.count
    end

    def self.parse_section_key(key)
      key = key.to_s
      if key.start_with?('v-')
        { kind: :volume, volume_number: key.delete_prefix('v-') }
      elsif key.start_with?('r-')
        { kind: :range, range: key.delete_prefix('r-') }
      end
    end

    private

    def scope
      @scope ||= filter_scope(Library::ChapterCatalog.chapters_scope_for_list(@fiction, @viewer))
    end

    def filter_scope(scope)
      return scope.where(id: @chapter_ids) if @chapter_ids.present?

      apply_section_filter(scope)
    end

    def list_order_sql
      if @order.to_sym == :desc
        Library::ChapterCatalog.order_clause_desc
      else
        Library::ChapterCatalog.order_clause
      end
    end

    def parse_chapter_ids(raw)
      return [] if raw.blank?

      raw.to_s.split(',').filter_map { |id| Integer(id, 10, exception: false) }.reject(&:zero?)
    end

    def apply_section_filter(scope)
      meta = self.class.parse_section_key(@section_key)
      raise ArgumentError, "invalid section key: #{@section_key}" unless meta

      case meta[:kind]
      when :volume
        scope.where(volume_number: meta[:volume_number])
      when :range
        range_chapters(scope, meta[:range])
      else
        raise ArgumentError, "invalid section kind: #{meta[:kind]}"
      end
    end

    # Same buckets as Chapters::ListSectionIndex.range_label (everything below 1 joins the first range), as a plain
    # range on number so index_chapters_on_fiction_volume_number can narrow it.
    def range_chapters(scope, range_label)
      start_num, end_num = parse_range_bounds(range_label)
      return Chapter.none unless start_num && end_num

      base = scope.where(volume_number: nil, number: ...(end_num + 1))
      start_num == 1 ? base : base.where(number: start_num..)
    end

    def parse_range_bounds(range_label)
      parts = range_label.to_s.split('-', 2).map(&:to_i)
      return nil unless parts.size == 2 && parts.all?(&:positive?)

      parts
    end
  end
end
