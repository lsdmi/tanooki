# frozen_string_literal: true

require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    advertisements(:advertisement_one)
  end

  test 'should get index with search' do
    Publication.stub :search, Publication.all do
      Fiction.stub :search, Fiction.all do
        get search_index_url, params: { search: ['test'] }
        assert_response :success
      end
    end
  end

  test 'should redirect to root without search' do
    get search_index_url
    assert_redirected_to root_path
  end

  test 'should add extra publications when searching by tag' do
    tag = tags(:one)
    tag_name = tag.name
    publications_with_tag = tag.publications
    excluded_ids = publications_with_tag.pluck(:id)

    searchkick = Searchkick.client

    Publication.stub :search, Publication.all do
      Fiction.stub :search, Fiction.all do
        Searchkick.stub :client, searchkick do
          searchkick.stub :ping, true do
            get search_index_url, params: { search: [tag_name] }
            results = assigns(:results)

            assert_includes results, publications(:tale_approved_one)
            assert_includes results, publications(:tale_created_one)

            count_without_main = results.count - 5
            num_to_add = 3 - (count_without_main % 3)

            extra_publications = Publication.all.order(created_at: :desc).where.not(id: excluded_ids).first(num_to_add)

            extra_publications.each do |publication|
              assert_includes results, publication
            end
          end
        end
      end
    end
  end

  test 'should add extra publications when searching by tag when es is turned off' do
    tag = tags(:one)
    tag_name = tag.name

    searchkick = Searchkick.client

    Publication.stub :search, Publication.all do
      Fiction.stub :search, Fiction.all do
        Searchkick.stub :client, searchkick do
          searchkick.stub :ping, false do
            get search_index_url, params: { search: [tag_name] }
            results = assigns(:results)

            assert_includes results, publications(:tale_approved_one)
          end
        end
      end
    end
  end
end
