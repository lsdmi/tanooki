# frozen_string_literal: true

# Join model linking publications to tags.
class PublicationTag < ApplicationRecord
  belongs_to :publication
  belongs_to :tag
end
