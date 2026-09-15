# frozen_string_literal: true

# Guest vs author access for unpublished blog publications.
module PublicationPublicAccess
  extend ActiveSupport::Concern

  private

  def load_publication_for_show
    id = params.expect(:id)
    key = Publications::PublicCache.show_key(id)
    cached = Rails.cache.read(key)
    return cached if cached&.published?

    publication = Publication.friendly.find(id)
    Publications::PublicCache.write_show(key, publication) if publication.published?
    publication
  end

  def redirect_if_publication_not_public
    return unless @publication.draft?

    if publication_author_access?
      redirect_to edit_publication_path(@publication)
    else
      redirect_to tales_path, alert: t('publications.alerts.not_yet_public')
    end
  end

  def publication_author_access?
    return false unless current_user

    current_user.admin? || @publication.user_id == current_user.id
  end
end
