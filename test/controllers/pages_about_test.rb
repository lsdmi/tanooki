# frozen_string_literal: true

require 'test_helper'

class PagesAboutTest < ActionDispatch::IntegrationTest
  test 'about page renders credentials and AboutPage JSON-LD' do
    get about_url

    assert_response :success
    assert_match StructuredData::SiteProfile::DESCRIPTION, response.body
    assert_match 'Досвід і спеціалізація', response.body

    about_ld = json_ld_type_from_response('AboutPage')
    assert_equal 'Про Баку', about_ld['name']
    assert about_ld.dig('mainEntity', 'description').present?
  end

  private

  def json_ld_type_from_response(type)
    response.body.scan(%r{<script type="application/ld\+json">\s*(.*?)\s*</script>}m).filter_map do |(fragment)|
      parsed = JSON.parse(fragment)
      parsed if parsed['@type'] == type
    rescue JSON::ParserError
      nil
    end.first
  end
end
