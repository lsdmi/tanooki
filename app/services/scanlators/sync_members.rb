# frozen_string_literal: true

module Scanlators
  # Adds and removes user memberships for a scanlator team.
  # Site admins and current team members may change the roster; others cannot.
  class SyncMembers
    attr_reader :member_ids, :scanlator, :user, :initial

    def initialize(member_ids, scanlator, user: nil, initial: false)
      @member_ids = member_ids
      @scanlator = scanlator
      @user = user
      @initial = initial
    end

    def call
      return if member_ids.nil?

      add_members
      remove_members
    end

    private

    def add_members
      members_to_add = effective_member_ids - existing_member_ids
      members_to_add.each { |user_id| scanlator.scanlator_users.create(user_id:) }
    end

    def remove_members
      members_to_remove = existing_member_ids - effective_member_ids
      members_to_remove.each { |user_id| scanlator.scanlator_users.find_by(user_id:).destroy }
    end

    def existing_member_ids
      scanlator.users.reload.ids
    end

    def requested_member_ids
      Array(member_ids).flatten.map(&:to_s).reject(&:blank?).map(&:to_i)
    end

    def effective_member_ids
      return requested_member_ids unless user

      ids = if user.admin? || roster_editable_by_user?
              requested_member_ids
            else
              existing_member_ids
            end
      include_creator_on_initial_roster(ids)
    end

    def include_creator_on_initial_roster(ids)
      return ids unless initial && !user.admin?
      return ids if ids.include?(user.id)

      ids + [user.id]
    end

    def roster_editable_by_user?
      return true if existing_member_ids.empty?

      existing_member_ids.include?(user.id)
    end
  end
end
