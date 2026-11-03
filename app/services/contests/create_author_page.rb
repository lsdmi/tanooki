# frozen_string_literal: true

module Contests
  # Ensures the user has a personal Scanlator (author page), creating one with default art.
  class CreateAuthorPage
    DEFAULT_AVATAR = Rails.root.join('app/assets/images/scanlator_avatar.webp').freeze
    DEFAULT_BANNER = Rails.root.join('app/assets/images/scanlator_banner.webp').freeze

    def self.call(user) = new(user).call

    def initialize(user)
      @user = user
    end

    def call
      existing = user.scanlators.order(:id).first
      return existing if existing

      create_personal_page
    end

    private

    attr_reader :user

    def create_personal_page
      scanlator = Scanlator.new(title: user.name, member_ids: [user.id.to_s])
      attach_defaults(scanlator)
      scanlator.save!
      Scanlators::SyncMembers.new(scanlator.member_ids, scanlator, user:, initial: true).call
      scanlator
    end

    def attach_defaults(scanlator)
      scanlator.avatar.attach(
        io: File.open(DEFAULT_AVATAR),
        filename: 'scanlator_avatar.webp',
        content_type: 'image/webp'
      )
      scanlator.banner.attach(
        io: File.open(DEFAULT_BANNER),
        filename: 'scanlator_banner.webp',
        content_type: 'image/webp'
      )
    end
  end
end
