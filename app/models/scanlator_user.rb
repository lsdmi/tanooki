# frozen_string_literal: true

class ScanlatorUser < ApplicationRecord
  belongs_to :scanlator
  belongs_to :user
end
