# frozen_string_literal: true

# Builds a contest-eligible fiction owned by a user's author page.
# Expects CoverUploadHelper (valid_cover_upload) on the including test case.
module ContestFictionHelper
  CONTEST_FICTION_DESCRIPTION = 'Короткий опис твору для конкурсу з достатньою довжиною тексту.'

  def create_contest_author_fiction(user:, title:, created_at: nil)
    scanlator = Contests::CreateAuthorPage.call(user)
    scanlator_ids = [scanlator.id.to_s]
    genre_ids = [genres(:original).id.to_s]
    fiction = build_contest_author_fiction(user:, title:, scanlator_ids:)
    fiction.genre_ids = genre_ids
    fiction.save!
    Fictions::SyncAssociations.new(fiction, genre_ids:, scanlator_ids:, user:).call
    fiction.update!(created_at:) if created_at
    fiction
  end

  private

  def build_contest_author_fiction(user:, title:, scanlator_ids:)
    Fiction.new(
      title:,
      description: CONTEST_FICTION_DESCRIPTION,
      author: user.name,
      origin: :ukrainian,
      content_rating: :everyone,
      scanlator_ids:,
      cover: valid_cover_upload
    )
  end
end
