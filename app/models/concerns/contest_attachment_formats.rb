# frozen_string_literal: true

# Content-type validation for Contest cover and entry placeholder attachments.
module ContestAttachmentFormats
  extend ActiveSupport::Concern

  IMAGE_TYPES = %w[image/jpeg image/png image/svg+xml image/webp].freeze

  included do
    validate :cover_format, :entry_placeholder_cover_format
  end

  private

  def cover_format
    attachment_format(:cover, IMAGE_TYPES)
  end

  def entry_placeholder_cover_format
    attachment_format(:entry_placeholder_cover, CoverImageValidator::ALLOWED_CONTENT_TYPES)
  end

  def attachment_format(name, allowed_types)
    return if attachment_changes[name.to_s].blank?

    attachment = public_send(name)
    return unless attachment.attached?
    return if attachment.content_type.in?(allowed_types)

    errors.add(name, :invalid_format)
  end
end
