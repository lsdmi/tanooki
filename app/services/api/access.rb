# frozen_string_literal: true

module Api
  # Team-scoped lookups for the API. An admin's token is an ordinary member's token:
  # nothing here calls User#manages_chapter?, #manages_fiction?, or Chapters::Authorization.
  # Membership is read on each call, so leaving a team takes effect on the next one.
  class Access
    def initialize(user)
      @user = user
    end

    def chapters
      Chapter.joins(:chapter_scanlators).where(chapter_scanlators: { scanlator_id: team_ids }).distinct
    end

    def chapter(id)
      chapters.find_by(id:)
    end

    def chapter!(id)
      chapter(id) || raise(Error.new('not_found', :not_found))
    end

    def fictions
      Fiction.joins(:fiction_scanlators).where(fiction_scanlators: { scanlator_id: team_ids }).distinct
    end

    def fiction(id_or_slug)
      key = id_or_slug.to_s
      fictions.find_by(id: key) || fictions.find_by(slug: key)
    end

    def fiction!(id_or_slug)
      fiction(id_or_slug) || raise(Error.new('not_found', :not_found))
    end

    # A revision is only reachable through a chapter this user can access, never by its own id.
    def revision(chapter_id, revision_id)
      record = chapter(chapter_id)
      return if record.nil? || record.class.reflect_on_association(:revisions).nil?

      record.revisions.find_by(id: revision_id)
    end

    # Every id has to be one of the user's teams. One foreign id rejects the whole list.
    def scanlator_ids!(fiction, ids)
      raise Error.new('licensed', :forbidden) if fiction.blank? || fiction.licensed?

      normalized = Array(ids).compact_blank.map(&:to_i).uniq.reject(&:zero?)
      return normalized if normalized.any? && (normalized - team_ids).none?

      raise Error.new('scanlator_ids', :unprocessable_entity)
    end

    # Drafts use the write scope. A published chapter also needs chapters:publish.
    def ensure_live_edit!(token, chapter)
      return if chapter.blank? || chapter.draft?
      return if token&.permits?('chapters:publish')

      raise Error.new('publish_scope', :forbidden)
    end

    def member_team_ids
      user.scanlators.ids
    end

    private

    def team_ids
      member_team_ids
    end

    attr_reader :user
  end
end
