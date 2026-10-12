# frozen_string_literal: true

module Chapters
  # «Усі · Команда А · Команда Б» above a fiction chapter list that has two translations.
  # An unknown team, or a fiction with one team, stays on «Усі».
  class TeamFilter
    attr_reader :teams

    def initialize(scanlator_id, teams:)
      @teams = teams
      @scanlator_id = chosen(scanlator_id)
    end

    def show? = @teams.size > 1

    def active? = !@scanlator_id.nil?

    def value = @scanlator_id

    def match?(chapter)
      return true unless active?

      team_ids(chapter).include?(@scanlator_id)
    end

    def sections(sections, listed)
      return sections unless active?

      keep(sections, listed)
    end

    def listed(chapters)
      return chapters unless active?

      prepare(chapters).select { |chapter| match?(chapter) }
    end

    private

    def chosen(scanlator_id)
      return if @teams.size < 2

      id = scanlator_id.to_i
      id if id.positive? && @teams.any? { |team| team.id == id }
    end

    def keep(sections, listed)
      prepare(listed)
      ids = listed.select { |chapter| match?(chapter) }.to_set(&:id)
      sections.filter_map do |section|
        shown = section[:chapter_ids].select { |chapter_id| ids.include?(chapter_id) }
        section.merge(chapter_ids: shown, all_chapter_ids: shown) if shown.any?
      end
    end

    def prepare(chapters)
      ActiveRecord::Associations::Preloader.new(records: chapters, associations: :scanlators).call
      chapters
    end

    def team_ids(chapter)
      chapter.scanlators.map(&:id)
    end
  end
end
