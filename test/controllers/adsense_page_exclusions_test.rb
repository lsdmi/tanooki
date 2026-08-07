# frozen_string_literal: true

require 'test_helper'

class AdsensePageExclusionsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include SearchControllerTesting
  include AdsensePageExclusionsTesting

  setup do
    sign_in users(:user_one)
  end

  test 'production disables auto ads on bookshelf show but keeps manual ads script' do
    in_production { assert_auto_ads_disabled_manual_enabled { get bookshelf_url(bookshelves(:one).sqid) } }
  end

  test 'production disables auto ads on chapter show but keeps manual ads script' do
    in_production { assert_auto_ads_disabled_manual_enabled { get chapter_url(chapters(:one)) } }
  end

  test 'production disables auto ads on fiction show but keeps manual ads script' do
    in_production { assert_auto_ads_disabled_manual_enabled { get fiction_url(fictions(:one)) } }
  end

  test 'production disables auto ads on genre show but keeps manual ads script' do
    in_production { assert_auto_ads_disabled_manual_enabled { get fiction_genre_fictions_url(genres(:one).slug) } }
  end

  test 'production disables auto ads on tale show but keeps manual ads script' do
    in_production do
      assert_auto_ads_disabled_manual_enabled do
        Search::TagCounts.stub(:call, {}) do
          Publication.stub :search, Publication.all do
            get tale_url(publications(:tale_approved_one))
          end
        end
      end
    end
  end

  test 'production disables auto ads on youtube video show but keeps manual ads script' do
    in_production do
      assert_auto_ads_disabled_manual_enabled do
        Search::TagCounts.stub(:call, {}) do
          get youtube_video_url(youtube_videos(:one))
        end
      end
    end
  end

  test 'production keeps adsense on search index' do
    in_production do
      assert_adsense_fully_enabled do
        with_stubbed_tag_counts do
          with_stubbed_search(Fiction, Publication, YoutubeVideo) do
            get search_index_url, params: { search: ['test'] }
          end
        end
      end
    end
  end

  test 'production keeps auto and manual adsense on bookshelf new' do
    in_production { assert_adsense_fully_enabled { get new_bookshelf_url } }
  end

  test 'production keeps auto and manual adsense on bookshelf edit' do
    in_production { assert_adsense_fully_enabled { get edit_bookshelf_url(bookshelves(:one).sqid) } }
  end

  test 'production keeps auto and manual adsense on chapter new' do
    in_production { assert_adsense_fully_enabled { get new_chapter_url(fiction: fictions(:one).slug) } }
  end

  test 'production keeps auto and manual adsense on chapter edit' do
    in_production { assert_adsense_fully_enabled { get edit_chapter_url(chapters(:one)) } }
  end

  test 'production keeps auto and manual adsense on fiction edit' do
    in_production { assert_adsense_fully_enabled { get edit_fiction_url(fictions(:one)) } }
  end

  test 'production keeps auto and manual adsense on tales index' do
    in_production do
      assert_adsense_fully_enabled do
        Search::TagCounts.stub(:call, {}) { get tales_url }
      end
    end
  end

  test 'production keeps auto and manual adsense on watch index' do
    in_production do
      assert_adsense_fully_enabled do
        Search::TagCounts.stub(:call, {}) { get youtube_videos_url }
      end
    end
  end

  test 'production disables all ads on copyright-excluded fiction show' do
    fiction = fictions(:one)
    fiction.update!(slug: FictionsController::AD_EXCLUDED_SLUGS.first)

    in_production { assert_adsense_fully_disabled { get fiction_url(fiction) } }
  end

  test 'production disables all ads on copyright-excluded fiction edit' do
    fiction = fictions(:one)
    fiction.update!(slug: FictionsController::AD_EXCLUDED_SLUGS.first)

    in_production { assert_adsense_fully_disabled { get edit_fiction_url(fiction) } }
  end
end
