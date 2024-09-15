# frozen_string_literal: true

class FictionDestroyService
  def initialize(fiction, current_user)
    @fiction = fiction
    @current_user = current_user
  end

  def call
    if @fiction.scanlators.size > 1
      destroy_associations
    else
      @fiction.destroy
    end
  end

  private

  def destroy_associations
    @current_user.scanlators.each do |scanlator|
      destroy_association(scanlator)
    end
  end

  def destroy_association(scanlator)
    chapters = @fiction.chapters.joins(:scanlators).where(chapter_scanlators: { scanlator_id: scanlator.id })
    chapters.destroy_all

    fiction_scanlator = FictionScanlator.find_by(fiction_id: @fiction.id, scanlator_id: scanlator.id)
    fiction_scanlator&.destroy
  end
end
