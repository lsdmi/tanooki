# frozen_string_literal: true

require 'test_helper'

class FictionListsAdsenseTest < ActionView::TestCase
  helper Adsense::PlacementsHelper
  helper do
    def adsense_allowed?
      false
    end

    def params
      @view_params || ActionController::Parameters.new
    end
  end

  test 'catalog ad slot renders a fiction_alphabetical preview in development' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      render partial: 'fiction_lists/catalog_ad_slot', locals: { wrapper_class: 'col-span-full' }
    end

    assert_select '.col-span-full #adsense-slot-fiction_alphabetical-catalog-grid-p1.reader-ad-slot--preview',
                  count: 1
  end

  test 'catalog ad slot is omitted outside development without live adsense' do
    render partial: 'fiction_lists/catalog_ad_slot'

    assert_select '#adsense-slot-fiction_alphabetical-catalog-grid-p1', count: 0
  end

  test 'list view key changes the navigation id' do
    @view_params = ActionController::Parameters.new(view: 'list', page: '2')

    Rails.stub(:env, ActiveSupport::StringInquirer.new('development')) do
      render partial: 'fiction_lists/catalog_ad_slot'
    end

    assert_select '#adsense-slot-fiction_alphabetical-catalog-list-p2', count: 1
  end
end
