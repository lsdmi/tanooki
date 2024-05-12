# frozen_string_literal: true

class FictionListsController < ApplicationController
  before_action :load_advertisement

  def alphabetical
    @fiction_hash_sorted = generate_alphabetical_fictions_hash

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

  def fictions
    params.except(:controller, :action).values.any?(&:present?) ? filtered_list : default_list
  end

  def filtered_list
    query = default_list
    query = filter_by_genre(query)
    query = filter_by_origin(query)
    query = filter_by_new(query)
    query = filter_by_long(query)
    query = filter_by_finished(query)

    query.all
  end

  def fictions_in_genre
    Fiction.joins(:genres).where(genres: { id: params['genre-radio'] }).ids
  end

  def longreads
    Chapter.group(:fiction_id).having('COUNT(chapters.id) > ?', 99).pluck(:fiction_id)
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

  def filter_by_genre(query)
    return query unless params['genre-radio'].present?

    query.includes(:genres).where(fictions: { id: fictions_in_genre })
  end

  def filter_by_origin(query)
    return query unless params['origin-radio'].present?

    query.where(origin: params['origin-radio'])
  end

  def filter_by_new(query)
    return query unless params[:only_new] == 'on'

    query.where(created_at: 3.months.ago...)
  end

  def filter_by_long(query)
    return query unless params[:only_long] == 'on'

    query.where(id: longreads)
  end

  def filter_by_finished(query)
    return query unless params[:only_finished] == 'on'

    query.finished
  end
end
