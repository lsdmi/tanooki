# frozen_string_literal: true

require 'test_helper'

class FictionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
    @fiction_two = fictions(:two)
  end

  test 'should get show' do
    [@fiction, @fiction_two].each do |fiction|
      Rails.cache.delete("fiction_#{fiction.id}")
      get fiction_url(fiction)

      assert_response :success
      assert_template :show
    end
  end

  test 'should get dashboard' do
    get blogs_path

    assert_response :redirect
    assert_redirected_to studio_index_path
  end

  test 'should get index' do
    get fictions_path

    assert_response :success

    index_presenter = assigns(:index_presenter)

    assert_instance_of FictionIndexPresenter, index_presenter
    verify_fiction_index_presenter_lists(index_presenter)
  end

  test 'should get new' do
    get new_fiction_url

    assert_response :success
  end

  test 'should create fiction' do
    assert_difference('Fiction.count') do
      post fictions_url, params: {
        fiction: {
          title: 'New Fiction',
          author: 'New Author',
          description: 'a' * 50,
          cover: Rack::Test::UploadedFile.new(
            Rails.root.join('app/assets/images/logo-default.svg'),
            'image/svg'
          ),
          scanlator_ids: [1],
          status: :announced,
          user_id: @fiction.user_id
        }
      }
    end

    assert_redirected_to fiction_path('new-fiction')
  end

  test 'should not create fiction with invalid params' do
    assert_no_difference('Fiction.count') do
      post fictions_url, params: { fiction: { title: '', author: '', user_id: @fiction.user_id } }
    end

    assert_response :unprocessable_content
  end

  test 'should get edit' do
    @fiction.stub :cover, ActiveStorage::Attachment.last do
      get edit_fiction_url(@fiction)

      assert_response :success
    end
  end

  test 'should update fiction' do
    patch fiction_url(@fiction), params: {
      fiction: {
        cover: Rack::Test::UploadedFile.new(Rails.root.join('app/assets/images/logo-default.svg'),
                                            'image/svg'),
        scanlator_ids: [1],
        title: 'Updated Title'
      }
    }

    assert_redirected_to fiction_path(@fiction)
    @fiction.reload

    assert_equal 'Updated Title', @fiction.title
  end

  test 'should not update fiction with invalid params' do
    patch fiction_url(@fiction), params: { fiction: { title: '' } }

    assert_response :unprocessable_content
    @fiction.reload

    assert_not_equal '', @fiction.title
  end

  test 'should destroy fiction' do
    assert_difference('Fiction.count', -1) { delete fiction_url(@fiction), as: :turbo_stream }

    assert_response :success
    assert_turbo_stream_flash_notice(I18n.t('fictions.notices.destroy_success'))
  end

  test 'should update fiction with genres' do
    genre_ids = Genre.all.sample(2).map(&:id)
    patch fiction_url(@fiction), params: { fiction: { genre_ids:, scanlator_ids: [1] } }

    assert_redirected_to fiction_path(@fiction)
    assert_equal genre_ids.sort, @fiction.genres.ids.sort
  end

  private

  def verify_fiction_index_presenter_lists(index_presenter)
    titles = [Fiction.find('two').title, Fiction.find('one').title]

    assert_equal advertisements(:advertisement_three), index_presenter.hero_ad
    assert_equal titles, index_presenter.popular_novelty.map(&:title)
    assert_equal titles, index_presenter.most_reads.map(&:title)
  end
end
