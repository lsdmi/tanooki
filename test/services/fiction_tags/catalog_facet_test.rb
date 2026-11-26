# frozen_string_literal: true

require 'test_helper'

module FictionTags
  class CatalogFacetTest < ActiveSupport::TestCase
    setup do
      @rebirth = fiction_tags(:rebirth)
      @litrpg = fiction_tags(:litrpg)
      @adult = FictionTag.create!(name: 'Омегаверс', explicit: true)
      fictions(:one).fiction_tags << [@rebirth, @adult]
      fictions(:two).fiction_tags << @rebirth
    end

    test 'options skip empty, hidden and adult ones' do
      assert_equal [@rebirth.slug], CatalogFacet.options(explicit: false).map(&:slug)
    end

    test 'options include adult tags only when they are allowed, alphabetically rather than by number of works' do
      # @rebirth has two works and @adult one, yet «Омегаверс» comes first.
      assert_equal [@adult.slug, @rebirth.slug], CatalogFacet.options(explicit: true).map(&:slug)
    end

    test 'selected keeps the requested order and skips unknown or hidden slugs' do
      slugs = [@litrpg.slug, 'no-such-tag', @rebirth.slug, fiction_tags(:yuri_hidden).slug]

      assert_equal [@litrpg, @rebirth], CatalogFacet.selected(slugs, explicit: false)
    end

    test 'selected leaves adult tags out unless they are allowed' do
      assert_empty CatalogFacet.selected([@adult.slug], explicit: false)
      assert_equal [@adult], CatalogFacet.selected([@adult.slug], explicit: true)
    end
  end
end
