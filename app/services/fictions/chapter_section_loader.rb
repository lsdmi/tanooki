# frozen_string_literal: true

module Fictions
  # Loads chapters for one fiction TOC accordion section (volume or numeric range).
  class ChapterSectionLoader
    include Library::ChapterCatalogHelper
    include ChaptersHelper

    def initialize(fiction:, viewer:, section_key:, order:, chapter_ids: nil)
      @fiction = fiction
      @viewer = viewer
      @section_key = section_key.to_s
      @order = order
      @chapter_ids = parse_chapter_ids(chapter_ids)
    end

    def call
      scope = chapters_scope_for_list(@fiction, @viewer)
      scoped = if @chapter_ids.present?
                 scope.where(id: @chapter_ids)
               else
                 apply_section_filter(scope)
               end
      order_sql = @order.to_sym == :desc ? order_clause_desc : order_clause
      scoped.includes(:scanlators).reorder(order_sql)
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

    def range_chapters(scope, range_label)
      unnumbered = scope.where(volume_number: nil)
      grouped = chapters_collection(unnumbered)
      records = grouped[range_label]
      return Chapter.none if records.blank?

      Chapter.where(id: records.map(&:id))
    end
  end
end
