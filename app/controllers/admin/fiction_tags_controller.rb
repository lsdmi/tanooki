# frozen_string_literal: true

module Admin
  # Moderation of fiction tags. Translators create tags freely (active at once); an admin reviews the
  # newest ones afterwards: rename, hide, mark 18+, merge into another tag, or delete.
  class FictionTagsController < ApplicationController
    FILTERS = %w[new all hidden].freeze
    NEW_FOR = 14.days
    PER_PAGE = 50

    before_action :authenticate_user!, :verify_user_permissions
    before_action :set_tag, only: %i[update destroy]

    def index
      @new_tag = FictionTag.new
      load_list
    end

    def create
      @new_tag = FictionTag.new(name: params.expect(fiction_tag: [:name])[:name])
      return created if @new_tag.save

      load_list
      render :index, status: :unprocessable_content
    end

    def update
      if @tag.update(params.expect(fiction_tag: %i[name status explicit]))
        redirect_back_or_to admin_fiction_tags_path, notice: t('admin.fiction_tags.updated', name: @tag.name),
                                                     status: :see_other
      else
        redirect_back_or_to admin_fiction_tags_path, alert: @tag.errors.messages.values.flatten.to_sentence,
                                                     status: :see_other
      end
    end

    def destroy
      count = @tag.fictions_count
      @tag.destroy!
      redirect_back_or_to admin_fiction_tags_path, notice: t('admin.fiction_tags.destroyed', name: @tag.name, count:),
                                                   status: :see_other
    end

    private

    def set_tag
      @tag = FictionTag.find(params.expect(:id))
    end

    def created
      redirect_to admin_fiction_tags_path(filter: 'new'), notice: t('admin.fiction_tags.created', name: @new_tag.name),
                                                          status: :see_other
    end

    def load_list
      @filter = FILTERS.include?(params[:filter]) ? params[:filter] : 'new'
      @query = params[:q].to_s.squish
      @counts = tab_counts
      @pagy, @tags = pagy(search(filtered), limit: PER_PAGE)
    end

    def tab_counts
      { 'new' => new_tags.count, 'all' => FictionTag.count, 'hidden' => FictionTag.hidden.count }
    end

    def new_tags
      FictionTag.where(created_at: NEW_FOR.ago..)
    end

    def filtered
      case @filter
      when 'new' then new_tags.order(created_at: :desc)
      when 'hidden' then FictionTag.hidden.order(:name)
      else FictionTag.order(:name)
      end
    end

    def search(tags)
      return tags if @query.blank?

      tags.where('fiction_tags.name LIKE ?', "%#{FictionTag.sanitize_sql_like(@query)}%")
    end
  end
end
