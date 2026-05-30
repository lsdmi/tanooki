# frozen_string_literal: true

module Fictions
  # Destroys a fiction owned by one team, or unlinks the current user's scanlators when shared.
  class DestroyOrUnlink
    def initialize(fiction, user)
      @fiction = fiction
      @user = user
    end

    def call
      if fiction.scanlators.size > 1
        unlink_user_scanlators
      else
        fiction.destroy
      end
    end

    private

    attr_reader :fiction, :user

    def unlink_user_scanlators
      user.scanlators.each do |scanlator|
        ScanlatorAssociationRemover.new(fiction, scanlator).call
      end
    end
  end
end
