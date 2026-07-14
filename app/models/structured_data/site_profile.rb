# frozen_string_literal: true

module StructuredData
  # Canonical copy for E-A-T signals: about page, Organization JSON-LD, and publisher metadata.
  module SiteProfile
    NAME = 'Бака'
    FOUNDING_YEAR = '2023'
    DESCRIPTION = 'Бака — де ранобе читають українською: переклади, блоги, відео й спільнота, яка тримає все це живим.'
    SOCIAL_URLS = [ExternalUrls.site_url].freeze
    EXPERTISE_TOPICS = [
      'українські переклади ранобе',
      'лайт-новели',
      'аніме-блоги',
      'веб-новели',
      'український YouTube про аніме'
    ].freeze

    def self.website_node(root)
      {
        '@type': 'WebSite',
        name: NAME,
        url: root,
        inLanguage: 'uk-UA',
        publisher: { '@id' => "#{root}#publisher" }
      }
    end

    def self.publisher_organization_data(root)
      {
        '@type': 'Organization',
        '@id' => "#{root}#publisher",
        name: NAME,
        url: root,
        description: DESCRIPTION,
        foundingDate: FOUNDING_YEAR,
        sameAs: SOCIAL_URLS,
        knowsAbout: EXPERTISE_TOPICS
      }
    end
  end
end
