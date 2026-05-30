# frozen_string_literal: true

# Form object for creating/updating a fiction with banner validation and association params.
class FictionForm
  include ActiveModel::Model

  attr_accessor :fiction, :params

  validate :banner_is_valid

  def save
    fiction.assign_attributes(params.except(:genre_ids, :scanlator_ids))
    assign_association_ids_from_params
    if valid? && fiction.save
      true
    else
      copy_errors_to_fiction
      false
    end
  end

  private

  def assign_association_ids_from_params
    fiction.genre_ids = params[:genre_ids] if params.key?(:genre_ids)
    fiction.scanlator_ids = params[:scanlator_ids] if params.key?(:scanlator_ids)
  end

  def banner_is_valid
    banner_file = params[:banner]
    return if banner_file.blank?

    validator = BannerImageValidator.new(banner_file)
    return if validator.valid?

    validator.errors.each { |msg| errors.add(:banner, msg) }
  end

  def copy_errors_to_fiction
    errors.each do |error|
      fiction.errors.add(error.attribute, error.message)
    end
  end
end
