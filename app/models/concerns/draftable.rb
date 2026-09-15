# frozen_string_literal: true

# Draft vs published lifecycle for user-authored records that keep one Action Text body.
module Draftable
  extend ActiveSupport::Concern

  included do
    enum :status, { draft: 'draft', published: 'published' }, default: :published, validate: true

    scope :drafts, -> { where(status: :draft) }
    scope :not_draft, -> { where.not(status: :draft) }
  end

  def public_visible?
    published? && !scheduled?
  end

  # Publications have no release clock. Chapter overrides with published_at.
  def scheduled?
    false
  end
end
