# frozen_string_literal: true

class FictionListsController < ApplicationController
  before_action :load_advertisement

  def alphabetical
    @fiction_hash_sorted = fetch_or_generate_cached_fictions
  end

  private

  def fetch_or_generate_cached_fictions
    Rails.cache.fetch('fictions_alphabetical', expires_in: 1.day) do
      generate_alphabetical_fictions_hash
    end
  end

  def generate_alphabetical_fictions_hash
    all_fictions = Fiction.includes([{ cover_attachment: :blob }, :chapters, :genres]).order(:title)
    fiction_hash = initialize_fiction_hash

    all_fictions.each do |fiction|
      first_letter = fiction.title[0].upcase
      add_fiction_to_hash(fiction_hash, first_letter, fiction)
    end

    fiction_hash.sort.to_h
  end

  def initialize_fiction_hash
    Hash.new { |hash, key| hash[key] = [] }
  end

  def add_fiction_to_hash(fiction_hash, first_letter, fiction)
    if first_letter =~ /\p{Cyrillic}/
      fiction_hash[first_letter] << fiction
    else
      fiction_hash['#'] << fiction
    end
  end
end
