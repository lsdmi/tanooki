# frozen_string_literal: true

module Fictions
  # Groups catalog fictions that share a normalized title, alternative title, or English title.
  # "Live" here is every fiction that is not soft-deleted: finished, stale, and announced
  # works still show up as duplicates. Blank fields and a fiction matching only itself are ignored.
  class DuplicateGroups
    TITLE_FIELDS = %i[title alternative_title english_title].freeze
    HEADER = %w[group slug title alternative_title english_title teams author chapters readers created].freeze

    # One fiction inside a duplicate group, with the fields the report prints.
    class Row
      attr_reader :readers

      delegate :slug, to: :fiction

      def initialize(fiction, readers)
        @fiction = fiction
        @readers = readers
      end

      def title = fiction.title.to_s
      def alternative_title = fiction.alternative_title.to_s
      def english_title = fiction.english_title.to_s
      def author = fiction.author.to_s
      def chapters = fiction.chapter_count
      def created_on = fiction.created_at.to_date
      def teams = fiction.scanlators.map(&:title).sort.join(', ')

      def tsv_fields
        [slug, title, alternative_title, english_title, teams, author, chapters, readers, created_on]
      end

      private

      attr_reader :fiction
    end

    # Disjoint-set so a title match chains into one group.
    class UnionFind
      def initialize(ids)
        @parent = ids.index_with { |id| id }
      end

      def union(left, right)
        left_root = find(left)
        right_root = find(right)
        @parent[right_root] = left_root unless left_root == right_root
      end

      def find(id)
        root = id
        root = @parent[root] while @parent[root] != root
        compress(id, root)
        root
      end

      private

      def compress(id, root)
        current = id
        until @parent[current] == root
          nxt = @parent[current]
          @parent[current] = root
          current = nxt
        end
      end
    end

    def self.normalize(value)
      value.to_s.downcase.gsub(/[^\p{L}\p{Nd}]/, '')
    end

    def call
      fictions = Fiction.includes(:scanlators).to_a
      readers = ReadingProgress.where(fiction_id: fictions.map(&:id)).group(:fiction_id).count
      group_fictions(fictions).map { |group| rows_for(group, readers) }.sort_by { |rows| group_sort_key(rows) }
    end

    def to_tsv
      groups = call
      warn "fictions=#{Fiction.count} groups=#{groups.size} rows=#{groups.sum(&:size)}"
      lines = groups.flat_map.with_index(1) { |rows, index| rows.map { |row| tsv_line(index, row) } }
      ([HEADER.join("\t")] + lines).join("\n")
    end

    private

    def group_fictions(fictions)
      union_find = UnionFind.new(fictions.map(&:id))
      link_shared_keys(fictions, union_find)
      grouped = fictions.group_by { |fiction| union_find.find(fiction.id) }
      grouped.values.select { |group| group.size > 1 }
    end

    def link_shared_keys(fictions, union_find)
      buckets = Hash.new { |hash, key| hash[key] = [] }
      fictions.each { |fiction| keys_for(fiction).each { |key| buckets[key] << fiction.id } }
      buckets.each_value { |ids| link_bucket(union_find, ids) }
    end

    def link_bucket(union_find, ids)
      return if ids.size < 2

      ids.drop(1).each { |id| union_find.union(ids.first, id) }
    end

    def keys_for(fiction)
      TITLE_FIELDS.filter_map { |field| self.class.normalize(fiction.public_send(field)).presence }.uniq
    end

    def rows_for(group, readers)
      group.map { |fiction| Row.new(fiction, readers.fetch(fiction.id, 0)) }.sort_by { |row| row_sort_key(row) }
    end

    def group_sort_key(rows)
      [-rows.sum(&:readers), rows.map(&:created_on).min, rows.map(&:slug).min]
    end

    def row_sort_key(row)
      [-row.readers, row.created_on, row.slug]
    end

    def tsv_line(index, row)
      ([index] + row.tsv_fields).map { |value| value.to_s.gsub(/[\t\r\n]+/, ' ') }.join("\t")
    end
  end
end
