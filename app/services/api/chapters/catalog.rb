# frozen_string_literal: true

module Api
  module Chapters
    # Chapter lists the REST controller and the MCP tools both use.
    class Catalog
      BATCH_LIMIT = 5
      BATCH_CHAR_LIMIT = 200_000

      def initialize(user)
        @access = Access.new(user)
      end

      def summaries(fiction_id, **)
        list(fiction_id, **).map { |chapter| Serialize.summary(chapter) }
      end

      def batch(fiction_id, **)
        capped(list(fiction_id, **)).map { |chapter| Serialize.full(chapter) }
      end

      def by_number(fiction_id, number, volume: nil, **)
        matches = numbered(fiction_id, number, volume, **)
        raise Error.new('not_found', :not_found) if matches.empty?
        raise ambiguous!(matches) if matches.many?

        Serialize.full(matches.first)
      end

      private

      attr_reader :access

      def list(fiction_id, team_id: nil, from: nil, to: nil)
        fiction = access.fiction!(fiction_id)
        scope = access.chapters.where(fiction_id: fiction.id).preload(:scanlators, :rich_text_content)
        filter_numbers(filter_team(scope, team_id), from, to).ordered_by_volume_and_number
      end

      def numbered(fiction_id, number, volume, **)
        scope = list(fiction_id, **).where(number:)
        return scope.to_a if volume.blank?

        scope.where(volume_number: volume).to_a
      end

      def filter_team(scope, team_id)
        return scope if team_id.blank?

        id = team_id.to_i
        raise Error.new('not_found', :not_found) unless access.member_team_ids.include?(id)

        scope.where(chapter_scanlators: { scanlator_id: id })
      end

      def filter_numbers(scope, from, to)
        scope = scope.where(number: (from)..) if from.present?
        scope = scope.where(number: ..(to)) if to.present?
        scope
      end

      def capped(chapters)
        picked = []
        chars = 0
        chapters.limit(BATCH_LIMIT).each do |chapter|
          html = chapter.content_html
          break if picked.any? && chars + html.length > BATCH_CHAR_LIMIT

          picked << chapter
          chars += html.length
        end
        picked
      end

      def ambiguous!(matches)
        Error.new('ambiguous', :conflict, { chapters: matches.map { |chapter| Serialize.summary(chapter) } })
      end
    end
  end
end
