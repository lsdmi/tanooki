# frozen_string_literal: true

require 'test_helper'

class FictionsControllerTagsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  TAG_SELECT = 'select#fiction_tag_names_select'

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'new form renders the multi-select wired to the fiction-tags controller' do
    get new_fiction_url

    assert_select "#{TAG_SELECT}[multiple][name='fiction[tag_names][]'][data-controller='fiction-tags']"
    assert_select '#fiction_tag_status [data-counter]', text: '0/10 теґів'
  end

  test 'new form offers active tags only' do
    get new_fiction_url

    assert_select "#{TAG_SELECT} option", text: 'Переродження'
    assert_select "#{TAG_SELECT} option", text: 'Юрі', count: 0
  end

  test 'edit form preselects saved tags including a hidden one the work carries' do
    @fiction.fiction_tags << [fiction_tags(:rebirth), fiction_tags(:yuri_hidden)]

    @fiction.stub :cover, ActiveStorage::Attachment.last do
      get edit_fiction_url(@fiction)
    end

    assert_select "#{TAG_SELECT} option[selected]", count: 2
    assert_select '#fiction_tag_status [data-counter]', text: '2/10 теґів'
  end

  test 'create links existing tags and makes brand-new ones active' do
    names = ['', 'переродження', '  #Академія   магії ']

    assert_difference ['Fiction.count', 'FictionTag.count'], 1 do
      post fictions_url, params: { fiction: new_fiction_params.merge(tag_names: names) }
    end

    fiction = Fiction.find('tagged-fiction')

    assert_equal ['Академія магії', 'Переродження'], fiction.fiction_tags.order(:name).pluck(:name)
    assert_predicate FictionTag.find_by!(name: 'Академія магії'), :active?
  end

  test 'create redirects to the new fiction' do
    post fictions_url, params: { fiction: new_fiction_params.merge(tag_names: ['Магія']) }

    assert_redirected_to fiction_path('tagged-fiction')
  end

  test 'update replaces tags' do
    patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], tag_names: ['', 'ЛітРПГ'] } }

    assert_equal ['ЛітРПГ'], @fiction.fiction_tags.pluck(:name)
  end

  test 'an empty submission clears the tags' do
    @fiction.fiction_tags << fiction_tags(:rebirth)

    patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], tag_names: [''] } }

    assert_redirected_to fiction_path(@fiction)
    assert_empty @fiction.reload.fiction_tags
  end

  test 'an update without tag_names leaves tags alone' do
    @fiction.fiction_tags << fiction_tags(:rebirth)

    patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], title: 'Still Tagged' } }

    assert_equal [fiction_tags(:rebirth)], @fiction.reload.fiction_tags.to_a
  end

  test 'too many tags re-renders the form with the message and saves nothing' do
    params = { fiction: { scanlator_ids: [1], title: 'Rejected', tag_names: eleven_names } }

    assert_no_difference ['FictionTag.count', 'FictionTagLink.count'] do
      patch fiction_url(@fiction), params:
    end

    assert_response :unprocessable_content
    assert_select '#fiction_tag_names', text: /Можна додати не більше 10 теґів/
  end

  test 'too many tags keeps the submitted choice selected and the title unchanged' do
    patch fiction_url(@fiction), params: { fiction: { scanlator_ids: [1], title: 'Rejected', tag_names: eleven_names } }

    assert_select "#{TAG_SELECT} option[selected]", count: 11
    assert_not_equal 'Rejected', @fiction.reload.title
  end

  private

  def eleven_names
    Array.new(FictionTag::MAX_PER_FICTION + 1) { |index| "Теґ номер #{index}" }
  end

  def new_fiction_params
    {
      title: 'Tagged Fiction', author: 'New Author', description: 'a' * 50,
      cover: valid_cover_upload, scanlator_ids: [1]
    }
  end
end
