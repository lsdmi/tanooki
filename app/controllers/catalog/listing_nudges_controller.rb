# frozen_string_literal: true

module Catalog
  # Team listing-nudge actions: mark complete or dismiss the current prompt.
  class ListingNudgesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_fiction
    before_action :authorize_fiction

    def complete
      Catalog::ListingNudge.new(@fiction).complete!
      redirect_back_or_to reading_path(@fiction), notice: t('fictions.listing_nudges.notices.completed')
    end

    def reopen
      Catalog::ListingNudge.new(@fiction).reopen!
      redirect_back_or_to reading_path(@fiction), notice: t('fictions.listing_nudges.notices.reopened')
    end

    def raise_expected
      Catalog::ListingNudge.new(@fiction).raise_expected!
      redirect_back_or_to reading_path(@fiction), notice: t('fictions.listing_nudges.notices.raised')
    end

    def clear_expected
      Catalog::ListingNudge.new(@fiction).clear_expected!
      redirect_back_or_to reading_path(@fiction), notice: t('fictions.listing_nudges.notices.cleared')
    end

    def dismiss
      Catalog::ListingNudge.new(@fiction).dismiss!
      redirect_back_or_to reading_path(@fiction), notice: t('fictions.listing_nudges.notices.dismissed')
    end

    private

    def set_fiction
      @fiction = Fiction.friendly.find(params.expect(:fiction_id))
    end

    def authorize_fiction
      return if Fictions::Authorization.new(current_user, @fiction).edit?

      redirect_to root_path
    end
  end
end
