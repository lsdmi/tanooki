# frozen_string_literal: true

class ScanlatorUsersManager
  attr_reader :member_ids, :scanlator

  def initialize(member_ids, scanlator)
    @member_ids = member_ids
    @scanlator = scanlator
  end

  def operate
    return if member_ids.nil?

    create_scanlator_users
    destory_scanlator_users
  end

  private

  def create_scanlator_users
    members_to_add = scanlator_users_ids - existing_member_ids
    members_to_add.each { |user_id| scanlator.scanlator_users.create(user_id:) }
  end

  def destory_scanlator_users
    members_to_remove = existing_member_ids - scanlator_users_ids
    members_to_remove.each { |user_id| scanlator.scanlator_users.find_by(user_id:).destroy }
  end

  def existing_member_ids
    scanlator.users.ids
  end

  def scanlator_users_ids
    member_ids.reject(&:empty?).map(&:to_i)
  end
end
