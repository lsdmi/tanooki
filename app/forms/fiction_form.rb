# frozen_string_literal: true

class FictionForm
  include ActiveModel::Model

  attr_accessor :fiction, :params

  validate :banner_is_valid

  def save
    fiction.assign_attributes(params)
    if valid? && fiction.save
      true
    else
      copy_errors_to_fiction
      false
    end
  end

  private

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
