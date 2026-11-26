# frozen_string_literal: true

require 'test_helper'

# Catalogue filter by tags (`/fictions?tags[]=…`): the list, the drawer, the chips and the empty state.
class FictionListsTagsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  LIST = '#fiction-list-page'

  setup do
    @rebirth = fiction_tags(:rebirth)
    @one = fictions(:one)
    @two = fictions(:two)
  end

  test 'one tag keeps only the works that carry it' do
    @one.fiction_tags << @rebirth

    get alphabetical_fictions_url, params: { tags: [@rebirth.slug] }

    assert_select "#{LIST} a[href=?]", fiction_path(@one)
    assert_select "#{LIST} a[href=?]", fiction_path(@two), count: 0
  end

  test 'the page offers the tag in the drawer and marks it as the active filter' do
    @one.fiction_tags << @rebirth

    get alphabetical_fictions_url, params: { tags: [@rebirth.slug] }

    assert_select 'input[type=checkbox][name="tags[]"][value=?][checked]', @rebirth.slug
    assert_select 'a[aria-label=?][href=?]', "Прибрати теґ «#{@rebirth.name}»", alphabetical_fictions_path
  end

  test 'the drawer lists tags in use and leaves hidden ones out' do
    @one.fiction_tags << @rebirth

    get alphabetical_fictions_url

    assert_select 'input[name="tags[]"][value=?]', @rebirth.slug
    assert_select 'input[name="tags[]"][value=?]', fiction_tags(:yuri_hidden).slug, count: 0
  end

  test 'the drawer renders every tag and offers a show-all button once there are more than the featured ones' do
    add_extra_tags(FictionTags::CatalogFacet::FEATURED + 1)

    get alphabetical_fictions_url

    total = FictionTags::CatalogFacet.options(explicit: false).size

    assert_select 'label[data-catalog-tag-search-target=item]', count: total
    assert_select 'button[data-catalog-tag-search-target=toggle]', text: /#{total}/, count: 1
  end

  test 'the drawer has no show-all button while every tag already fits' do
    @one.fiction_tags << @rebirth

    get alphabetical_fictions_url

    assert_operator FictionTags::CatalogFacet.options(explicit: false).size, :<=, FictionTags::CatalogFacet::FEATURED
    assert_select 'button[data-catalog-tag-search-target=toggle]', count: 0
  end

  test 'an unknown tag shows the tag empty state with a reset link' do
    get alphabetical_fictions_url, params: { tags: ['no-such-tag'] }

    assert_includes response.body, I18n.t('fiction_lists.empty.tags_title')
    assert_select "#{LIST} a[href=?]", alphabetical_fictions_path, text: I18n.t('fiction_lists.empty.tags_reset')
  end

  test 'a reader without 18+ is told why an adult tag shows nothing' do
    adult = FictionTag.create!(name: 'Омегаверс', explicit: true)
    @one.fiction_tags << adult

    get alphabetical_fictions_url, params: { tags: [adult.slug] }

    assert_select "#{LIST} a[href=?]", fiction_path(@one), count: 0
    assert_includes response.body, I18n.t('fiction_lists.empty.tags_adult_hint')
  end

  test 'turning 18+ on lets the adult tag through' do
    adult = FictionTag.create!(name: 'Омегаверс', explicit: true)
    @one.fiction_tags << adult

    get alphabetical_fictions_url, params: { tags: [adult.slug], include_eighteen: '1' }

    assert_select "#{LIST} a[href=?]", fiction_path(@one)
  end

  test 'a hidden genre keeps its works out even when they carry the tag' do
    sign_in users(:user_two)
    FictionGenre.create!(fiction: @one, genre: genres(:bl))
    @one.fiction_tags << @rebirth

    get alphabetical_fictions_url, params: { tags: [@rebirth.slug] }

    assert_select "#{LIST} a[href=?]", fiction_path(@one), count: 0
  end

  test 'a tag-filtered page is noindex but still followed' do
    get alphabetical_fictions_url, params: { tags: [@rebirth.slug] }

    assert_select 'meta[name=robots][content=?]', 'noindex, follow'
  end

  test 'the plain catalogue keeps the default robots' do
    get alphabetical_fictions_url

    assert_select 'meta[name=robots][content=?]', 'max-image-preview:large'
  end

  private

  # A work carries at most FictionTag::MAX_PER_FICTION tags, so spread them over several works.
  def add_extra_tags(count)
    works = [@one, @two]
    count.times do |index|
      works[index % works.size].fiction_tags << FictionTag.create!(name: "теґ номер #{index}")
    end
  end
end
