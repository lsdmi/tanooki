# frozen_string_literal: true

module Api
  module Fictions
    # Fictions the caller's teams work on, with the latest chapter number of each of those teams.
    class MineQuery
      def self.call(user, query: nil)
        new(user, query).call
      end

      def initialize(user, query)
        @user = user
        @query = query.to_s.squish
      end

      def call
        fictions.map { |fiction| entry(fiction) }
      end

      private

      attr_reader :user, :query

      def fictions
        scope = Access.new(user).fictions.includes(:scanlators).order(:title)
        return scope if query.blank?

        like = "%#{Fiction.sanitize_sql_like(query)}%"
        scope.where('fictions.title LIKE :q OR fictions.alternative_title LIKE :q', q: like)
      end

      def entry(fiction)
        {
          id: fiction.id,
          slug: fiction.slug,
          title: fiction.title,
          original_title: fiction.alternative_title.presence || fiction.english_title,
          teams: teams_for(fiction)
        }
      end

      def teams_for(fiction)
        mine = fiction.scanlators.select { |team| member_ids.include?(team.id) }
        mine.sort_by(&:title).map do |team|
          { id: team.id, name: team.title, last_chapter_number: last_number(fiction, team) }
        end
      end

      def last_number(fiction, team)
        number = Access.new(user).chapters.where(fiction_id: fiction.id)
                       .where(chapter_scanlators: { scanlator_id: team.id }).maximum(:number)
        Chapters::Serialize.json_number(number)
      end

      def member_ids
        @member_ids ||= user.scanlators.ids
      end
    end
  end
end
