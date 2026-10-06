# frozen_string_literal: true

# Team donation (`bank_url`) and extra links. Readers see them as outbound buttons on every chapter, and URL
# reputation scanners treat "payment button → unknown host" as phishing, so both must be plain https links to a
# real host (no `user@host`, IPs, shorteners or Russian domains), and the donation link must point at a known
# donation service. Values saved before these rules are not rendered unless they pass them.
module ScanlatorLinks
  extend ActiveSupport::Concern

  DONATION_SERVICES = {
    'monobank.ua' => 'monobank',
    'privat24.ua' => 'Privat24',
    'donatello.to' => 'Donatello',
    'diaka.ua' => 'Diaka',
    'buymeacoffee.com' => 'Buy Me a Coffee',
    'ko-fi.com' => 'Ko-fi',
    'patreon.com' => 'Patreon'
  }.freeze

  SHORTENER_HOSTS = %w[bit.ly cutt.ly goo.gl is.gd ow.ly rebrand.ly shorturl.at t.co tiny.cc tinyurl.com].freeze

  RUSSIAN_ZONES = %w[ru su рф xn--p1ai].freeze

  included do
    normalizes :bank_url, :extra_url, with: ->(value) { ScanlatorLinks.normalize(value) }

    validates :bank_url, :extra_url, length: { maximum: 500 }
    validate :bank_url_on_donation_service, if: :will_save_change_to_bank_url?
    validate :extra_url_safe, if: :will_save_change_to_extra_url?
  end

  class << self
    def normalize(value)
      url = value.strip
      return if url.empty?

      url = url.sub(%r{\Ahttp://}i, 'https://')
      url = "https://#{url}" unless url.match?(%r{\A[a-z][a-z\d+.-]*://}i)
      url.gsub(/[^[:ascii:]]|\s/) { |char| ERB::Util.url_encode(char) }
    end

    def safe_uri(value)
      uri = parse(value)
      uri if uri.is_a?(URI::HTTPS) && uri.userinfo.nil? && public_host?(uri.host.to_s.downcase)
    end

    def russian?(value)
      host = URI.decode_www_form_component(parse(value)&.host.to_s).downcase
      RUSSIAN_ZONES.include?(host.split('.').last)
    end

    def donation_service(uri)
      host = uri.host.downcase
      DONATION_SERVICES.find { |domain, _| host == domain || host.end_with?(".#{domain}") }&.last
    end

    private

    def parse(value)
      URI.parse(normalize(value)) if value.present?
    rescue URI::InvalidURIError
      nil
    end

    # A `%` means a non-ASCII hostname that normalize had to escape; real IDN hosts arrive as punycode.
    def public_host?(host)
      host.include?('.') && host.exclude?('%') && !host.start_with?('[') && !host.match?(/\A[\d.]+\z/) &&
        SHORTENER_HOSTS.exclude?(host) && RUSSIAN_ZONES.exclude?(host.split('.').last)
    end
  end

  def donation_url
    uri = ScanlatorLinks.safe_uri(bank_url)
    uri.to_s if uri && ScanlatorLinks.donation_service(uri)
  end

  def donation_service
    uri = ScanlatorLinks.safe_uri(bank_url)
    ScanlatorLinks.donation_service(uri) if uri
  end

  def extra_link_url
    ScanlatorLinks.safe_uri(extra_url)&.to_s
  end

  private

  def bank_url_on_donation_service
    return if bank_url.blank? || donation_url

    if ScanlatorLinks.safe_uri(bank_url)
      services = DONATION_SERVICES.values.to_sentence(last_word_connector: ' або ')
      errors.add(:bank_url, :unsupported_service, services:)
    else
      errors.add(:bank_url, unsafe_link_error(bank_url))
    end
  end

  def extra_url_safe
    errors.add(:extra_url, unsafe_link_error(extra_url)) if extra_url.present? && extra_link_url.nil?
  end

  def unsafe_link_error(value)
    ScanlatorLinks.russian?(value) ? :russian_domain : :unsafe
  end
end
