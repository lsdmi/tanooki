# frozen_string_literal: true

# Editorial pack for ACQUISITION_AND_HITS_SPIKE §2.3.
#
#   bin/rails seo:acquisition_tales            # drafts + refresh
#   bin/rails seo:acquisition_tales:drafts
#   bin/rails seo:acquisition_tales:refresh
namespace :seo do
  namespace :acquisition_tales do
    desc 'Create demand-led draft Tales with links into the catalog'
    task drafts: :environment do
      Seo::AcquisitionTales.run_drafts! { |msg| puts msg }
    end

    desc 'Append catalog CTA to high-impression Tales (idempotent)'
    task refresh: :environment do
      Seo::AcquisitionTales.run_refresh! { |msg| puts msg }
    end

    desc 'Drafts + refresh (§2.3.1 + §2.3.2)'
    task all: %i[drafts refresh]
  end

  desc 'Alias: seo:acquisition_tales:all'
  task acquisition_tales: 'seo:acquisition_tales:all'
end
