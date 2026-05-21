# frozen_string_literal: true

# Join model linking fictions to scanlator teams.
class FictionScanlator < ApplicationRecord
  belongs_to :fiction
  belongs_to :scanlator
end
