# frozen_string_literal: true

require 'test_helper'

class FictionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'should get show' do
    Rails.cache.delete("fiction_#{params[:id]}")
    get fiction_url(@fiction)
    assert_response :success
    assert_template :show
    assert_not_nil assigns(:fiction)
    assert_not_nil assigns(:commentable)
    assert_not_nil assigns(:comments)
    assert_not_nil assigns(:comment)
    assert_instance_of Comment, assigns(:comment)
  end

  test 'should get dashboard' do
    get blogs_path
    assert_response :success
  end

  test 'should get index' do
    get fictions_path
    assert_response :success

    assert_not_nil assigns(:hero_ad)
    assert_equal advertisements(:advertisement_three), assigns(:hero_ad)

    assert_not_nil assigns(:popular_fictions)
    assert_equal 2, assigns(:popular_fictions).count

    assert_not_nil assigns(:most_reads)
    assert_equal [Fiction.find('two').title, Fiction.find('one').title], assigns(:most_reads).map(&:title)

    assert_not_nil assigns(:latest_updates)
    assert_not_nil assigns(:hot_updates)
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
            Rails.root.join('app', 'assets', 'images', 'logo.svg'),
            'image/svg'
          ),
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

    assert_response :unprocessable_entity
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
        cover: Rack::Test::UploadedFile.new(
          Rails.root.join('app', 'assets', 'images', 'logo.svg'),
          'image/svg'
        ),
        title: 'Updated Title'
      }
    }
    assert_redirected_to fiction_path(@fiction)
    @fiction.reload
    assert_equal 'Updated Title', @fiction.title
  end

  test 'should not update fiction with invalid params' do
    patch fiction_url(@fiction), params: { fiction: { title: '' } }
    assert_response :unprocessable_entity
    @fiction.reload
    assert_not_equal '', @fiction.title
  end

  test 'should destroy fiction' do
    assert_difference('Fiction.count', -1) do
      delete fiction_url(@fiction)
    end

    assert_response :success
  end

  test 'should update fiction with genres' do
    genre_ids = Genre.all.sample(2).map(&:id)
    patch fiction_url(@fiction), params: { fiction: { genre_ids: } }
    assert_redirected_to fiction_path(@fiction)
    assert_equal genre_ids.sort, @fiction.genres.ids.sort
  end

  private

  def params
    { id: @fiction.id }
  end
end
