# frozen_string_literal: true

require 'test_helper'

class ScanlatorsMetaTest < ActionDispatch::IntegrationTest
  test 'show exposes website og type and summary twitter card' do
    scanlator = scanlators(:one)

    get scanlator_path(scanlator)

    assert_select 'meta[property="og:type"][content=?]', 'website'
    assert_select 'meta[name="twitter:card"][content=?]', 'summary'
    assert_select 'link[rel="canonical"][href=?]', scanlator_url(scanlator)
  end

  test 'show ProfilePage JSON-LD names the team organization' do
    scanlator = scanlators(:one)

    get scanlator_path(scanlator)
    entity = profile_page_ld_from_response.fetch('mainEntity')

    assert_equal 'Organization', entity['@type']
    assert_equal scanlator.title, entity['name']
  end

  test 'show ProfilePage JSON-LD uses absolute image and telegram sameAs' do
    scanlator = scanlators(:one)

    get scanlator_path(scanlator)
    entity = profile_page_ld_from_response.fetch('mainEntity')

    assert_match(%r{\Ahttps?://}, entity['image'])
    assert_equal ["https://telegram.me/#{scanlator.telegram_id}"], entity['sameAs']
  end

  test 'show JSON-LD omits null sameAs and uses absolute default avatar' do
    get scanlator_path(scanlators(:two))
    entity = profile_page_ld_from_response.fetch('mainEntity')

    assert_nil entity['sameAs']
    assert_nil entity['description']
    assert_match(%r{\Ahttps?://.+/assets/scanlator_avatar}, entity['image'])
  end

  private

  def profile_page_ld_from_response
    response.body.scan(%r{<script type="application/ld\+json">\s*(.*?)\s*</script>}m).filter_map do |(fragment)|
      parsed = JSON.parse(fragment)
      parsed if parsed['@type'] == 'ProfilePage'
    rescue JSON::ParserError
      nil
    end.first
  end
end
