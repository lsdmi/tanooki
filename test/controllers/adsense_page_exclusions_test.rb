# frozen_string_literal: true

require 'test_helper'

class AdsensePageExclusionsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include SearchControllerTesting

  setup do
    sign_in users(:user_one)
  end

  test 'production disables adsense on bookshelf show' do
    in_production { assert_adsense_disabled { get bookshelf_url(bookshelves(:one).sqid) } }
  end

  test 'production disables adsense on chapter show' do
    in_production { assert_adsense_disabled { get chapter_url(chapters(:one)) } }
  end

  test 'production disables adsense on fiction show' do
    in_production { assert_adsense_disabled { get fiction_url(fictions(:one)) } }
  end

  test 'production disables adsense on genre show' do
    in_production { assert_adsense_disabled { get fiction_genre_fictions_url(genres(:one).slug) } }
  end

  test 'production disables adsense on tale show' do
    in_production do
      assert_adsense_disabled do
        Search::TagCounts.stub(:call, {}) do
          Publication.stub :search, Publication.all do
            get tale_url(publications(:tale_approved_one))
          end
        end
      end
    end
  end

  test 'production disables adsense on youtube video show' do
    in_production do
      assert_adsense_disabled do
        Search::TagCounts.stub(:call, {}) do
          get youtube_video_url(youtube_videos(:one))
        end
      end
    end
  end

  test 'production disables adsense on search index' do
    in_production do
      assert_adsense_disabled do
        with_stubbed_tag_counts do
          with_stubbed_search(Fiction, Publication, YoutubeVideo) do
            get search_index_url, params: { search: ['test'] }
          end
        end
      end
    end
  end

  test 'production keeps adsense on bookshelf new' do
    in_production { assert_adsense_enabled { get new_bookshelf_url } }
  end

  test 'production keeps adsense on bookshelf edit' do
    in_production { assert_adsense_enabled { get edit_bookshelf_url(bookshelves(:one).sqid) } }
  end

  test 'production keeps adsense on chapter new' do
    in_production { assert_adsense_enabled { get new_chapter_url(fiction: fictions(:one).slug) } }
  end

  test 'production keeps adsense on chapter edit' do
    in_production { assert_adsense_enabled { get edit_chapter_url(chapters(:one)) } }
  end

  test 'production keeps adsense on fiction edit' do
    in_production { assert_adsense_enabled { get edit_fiction_url(fictions(:one)) } }
  end

  test 'production keeps adsense on tales index' do
    in_production do
      assert_adsense_enabled do
        Search::TagCounts.stub(:call, {}) { get tales_url }
      end
    end
  end

  test 'production keeps adsense on watch index' do
    in_production do
      assert_adsense_enabled do
        Search::TagCounts.stub(:call, {}) { get youtube_videos_url }
      end
    end
  end

  test 'production disables adsense on fiction edit for copyright-excluded slugs' do
    fiction = fictions(:one)
    fiction.update!(slug: FictionsController::AD_EXCLUDED_SLUGS.first)

    in_production { assert_adsense_disabled { get edit_fiction_url(fiction) } }
  end

  private

  def in_production(&)
    Rails.stub(:env, ActiveSupport::StringInquirer.new('production'), &)
  end

  def assert_adsense_disabled
    yield

    assert_response :success
    assert_select 'body[data-load-adsense="false"]', count: 1
  end

  def assert_adsense_enabled
    yield

    assert_response :success
    assert_select 'body[data-load-adsense="true"]', count: 1
  end
end
