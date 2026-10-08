# frozen_string_literal: true

# Form object for creating/updating a fiction with banner validation and association params.
class FictionForm
  include ActiveModel::Model

  attr_accessor :fiction, :params, :user

  validate :banner_is_valid
  validate :cover_is_valid

  FORM_ONLY_PARAMS = %i[
    genre_ids scanlator_ids expected_chapters complete licensed license_publisher license_url
    different_work
  ].freeze

  attr_reader :title_matches

  def save
    @title_matches = []
    return false unless normalize_cover_upload

    assign_from_params
    duplicate = blocking_title_match?
    if !duplicate && valid? && fiction.save
      fiction
    else
      copy_errors_to_fiction
      nil
    end
  end

  def license_clear_denied?
    @license.present? && @license.clear_denied?
  end

  private

  def assign_from_params
    fiction.assign_attributes(params.except(*FORM_ONLY_PARAMS))
    apply_listing_editorial
    apply_license
    assign_association_ids_from_params
  end

  def apply_license
    return unless param?(:licensed)

    @license = Catalog::ApplyLicense.call(
      fiction, actor: user, licensed: params[:licensed],
               publisher: params[:license_publisher], url: params[:license_url]
    )
  end

  def assign_association_ids_from_params
    fiction.genre_ids = params[:genre_ids] if params.key?(:genre_ids)
    fiction.scanlator_ids = params[:scanlator_ids] if params.key?(:scanlator_ids)
  end

  def apply_listing_editorial
    fields = editorial_fields
    return if fields.empty?

    Catalog::UpdateListingEditorial.call(fiction, **fields)
  end

  def editorial_fields
    fields = {}
    fields[:expected] = params[:expected_chapters] if param?(:expected_chapters)
    fields[:complete] = params[:complete] if param?(:complete)
    fields
  end

  def param?(key)
    params.key?(key) || params.key?(key.to_s)
  end

  # Edit is never blocked. A checked "different work" box creates the fiction anyway.
  def blocking_title_match?
    return false if fiction.persisted?

    @title_matches = Fictions::ExactTitleMatch.new(title: fiction.title, english_title: fiction.english_title).call
    @title_matches.any? && !different_work?
  end

  def different_work?
    ActiveModel::Type::Boolean.new.cast(params[:different_work])
  end

  def banner_is_valid
    banner_file = params[:banner]
    return if banner_file.blank?

    validator = BannerImageValidator.new(banner_file)
    return if validator.valid?

    validator.errors.each { |msg| errors.add(:banner, msg) }
  end

  def cover_is_valid
    cover_file = params[:cover]
    return if cover_file.blank?

    validator = CoverImageValidator.new(cover_file)
    return if validator.valid?

    validator.errors.each { |msg| errors.add(:cover, msg) }
  end

  def normalize_cover_upload
    cover_file = params[:cover]
    return true if cover_file.blank?

    params[:cover] = Fictions::CoverUploadNormalizer.call(cover_file)
    true
  rescue Fictions::CoverUploadNormalizer::Error => e
    errors.add(:cover, e.message)
    false
  end

  def copy_errors_to_fiction
    errors.each do |error|
      fiction.errors.add(error.attribute, error.message)
    end
  end
end
