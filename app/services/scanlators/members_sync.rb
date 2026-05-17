# frozen_string_literal: true

module Scanlators
  # Adds and removes user memberships for a scanlator team from submitted member IDs.
  class MembersSync
    attr_reader :member_ids, :scanlator

    def initialize(member_ids, scanlator)
      @member_ids = member_ids
      @scanlator = scanlator
    end

    def operate
      return if member_ids.nil?

      add_members
      remove_members
    end

    private

    def add_members
      members_to_add = requested_member_ids - existing_member_ids
      members_to_add.each { |user_id| scanlator.scanlator_users.create(user_id:) }
    end

    def remove_members
      members_to_remove = existing_member_ids - requested_member_ids
      members_to_remove.each { |user_id| scanlator.scanlator_users.find_by(user_id:).destroy }
    end

    def existing_member_ids
      scanlator.users.ids
    end

    def requested_member_ids
      member_ids.reject(&:empty?).map(&:to_i)
    end
  end
end
