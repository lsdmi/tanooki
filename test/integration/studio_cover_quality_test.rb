# frozen_string_literal: true

require 'test_helper'

class StudioCoverQualityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include CoverUploadHelper

  test 'writings tab shows cover quality flag for fiction with weak cover' do
    fiction = fictions(:one)
    fiction.cover.attach(valid_cover_upload)

    sign_in users(:user_one)

    FastImage.stub(:size, [500, 700]) do
      get studio_index_path(tab: 'writings')
    end

    assert_response :success
    assert_select 'p', text: /Ширина обкладинки має бути не менше 600px/
  end
end
