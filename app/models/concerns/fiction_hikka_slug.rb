# frozen_string_literal: true

# The Hikka title this fiction matches. Hikka (укр. MAL) reads the slug from our public API, so one Hikka title
# belongs to at most one fiction. A slug that Hikka answers with 404 is rejected; an unreachable Hikka only warns.
module FictionHikkaSlug
  extend ActiveSupport::Concern

  included do
    normalizes :hikka_slug, with: ->(value) { Fictions::HikkaSlug.normalize(value) }
    validates :hikka_slug,
              length: { maximum: Fictions::HikkaSlug::MAX_LENGTH },
              format: { with: Fictions::HikkaSlug::FORMAT },
              uniqueness: true,
              allow_nil: true
    validate :hikka_slug_exists_on_hikka

    # A soft-deleted fiction must not keep the title: the unique index counts deleted rows too.
    before_destroy :clear_hikka_slug_on_delete

    # Set when Hikka could not be asked. The save still goes through; the form shows this as a warning.
    attr_reader :hikka_slug_warning
  end

  INDEX_NAME = 'index_fictions_on_hikka_slug'

  # The uniqueness validation checks first, but two saves can pass it together; the unique index then rejects the
  # second one. Report that as the same "taken" error instead of a 500. Other unique violations still raise.
  def save(**)
    super
  rescue ActiveRecord::RecordNotUnique => e
    raise unless e.message.include?(INDEX_NAME)

    errors.add(:hikka_slug, :taken)
    false
  end

  private

  # Runs inside SoftDeletable#soft_delete's transaction, so a rolled-back delete keeps the slug too. Skips validations
  # on purpose: a deleted fiction must lose its title even when some other field would fail validation.
  def clear_hikka_slug_on_delete
    return unless persisted? && hikka_slug.present?

    self.hikka_slug = nil
    save!(validate: false)
  end

  def hikka_slug_exists_on_hikka
    @hikka_slug_warning = nil
    return unless will_save_change_to_hikka_slug? && hikka_slug.present?
    return if errors.include?(:hikka_slug)

    case hikka_slug_lookup_result
    when :not_found then errors.add(:hikka_slug, :not_found_on_hikka)
    when :unavailable then @hikka_slug_warning = :hikka_unavailable
    end
  end

  # Validation can run more than once per save; ask Hikka once per value.
  def hikka_slug_lookup_result
    return @hikka_slug_lookup.last if @hikka_slug_lookup&.first == hikka_slug

    result = Fictions::HikkaLookup.new(hikka_slug).call
    @hikka_slug_lookup = [hikka_slug, result]
    result
  end
end
