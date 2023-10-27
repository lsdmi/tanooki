# frozen_string_literal: true

class FictionScanlator < ApplicationRecord
  belongs_to :fiction
  belongs_to :scanlator
end
