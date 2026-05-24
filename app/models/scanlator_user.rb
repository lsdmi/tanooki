# frozen_string_literal: true

# Join model linking users to scanlator teams.
class ScanlatorUser < ApplicationRecord
  belongs_to :scanlator, counter_cache: :members_count
  belongs_to :user
end
