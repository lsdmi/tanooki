# frozen_string_literal: true

# One catalogue cut an account turned on. A reader may keep two of these.
class UserHiddenPackage < ApplicationRecord
  belongs_to :user, inverse_of: :hidden_packages

  validates :package_key, inclusion: { in: ->(_) { ContentFilters::Packages.keys } }
  validates :package_key, uniqueness: { scope: :user_id }
end
