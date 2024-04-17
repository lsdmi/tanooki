# frozen_string_literal: true

class FictionListsController < ApplicationController
  before_action :load_advertisement

  def alphabetical
    @fiction_hash_sorted = fetch_or_generate_cached_fictions

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [refresh_letters, refresh_fictions]
      end
    end
  end

  private

  def default_list
    Rails.cache.fetch('default_fictions_alphabetical', expires_in: 1.day) do
      Fiction.includes([{ cover_attachment: :blob }, :chapters, :genres]).order(:title)
    end
  end

  def fetch_or_generate_cached_fictions
    generate_alphabetical_fictions_hash
  end

  def fictions
    params[:only_finished] == "on" ? finished_list : default_list
  end

  def finished_list
    Rails.cache.fetch('finished_fictions_alphabetical', expires_in: 1.day) do
      Fiction.finished.includes([{ cover_attachment: :blob }, :chapters, :genres]).order(:title)
    end
  end

  def generate_alphabetical_fictions_hash
    fiction_hash = initialize_fiction_hash

    fictions.each do |fiction|
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

  def refresh_letters
    turbo_stream.update(
      'letter-list',
      partial: 'fiction_lists/letter_list',
      locals: { fiction_hash_sorted: @fiction_hash_sorted }
    )
  end

  def refresh_fictions
    turbo_stream.update(
      'fiction-list',
      partial: 'fiction_lists/fiction_list',
      locals: { fiction_hash_sorted: @fiction_hash_sorted }
    )
  end
end
