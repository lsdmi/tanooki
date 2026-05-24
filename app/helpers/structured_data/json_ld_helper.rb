# frozen_string_literal: true

module StructuredData
  # Schema.org JSON-LD payloads and script tags for layout and Open Graph meta.
  module JsonLdHelper
    include JsonLdScriptHelper
    include JsonLdPageHelper
    include JsonLdContentHelper
    include JsonLdEntitiesHelper
  end
end
