# frozen_string_literal: true

# Destroys fiction or drops the current user's scanlator link when shared.
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
      Fictions::ScanlatorAssociationRemover.new(@fiction, scanlator).call
    end
  end
end
