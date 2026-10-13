# frozen_string_literal: true

# Fiction-level thanks total from chapter counter caches. Display-only; no fiction thank button.
module FictionThanks
  extend ActiveSupport::Concern

  def thanks_count
    chapters.sum(:thanks_count)
  end
end
