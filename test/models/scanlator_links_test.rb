# frozen_string_literal: true

require 'test_helper'

class ScanlatorLinksTest < ActiveSupport::TestCase
  setup do
    @scanlator = scanlators(:one)
  end

  test 'adds https to links typed without a scheme and upgrades http' do
    @scanlator.bank_url = ' send.monobank.ua/jar/abc '
    @scanlator.extra_url = 'http://telegram.me/team'

    assert_equal 'https://send.monobank.ua/jar/abc', @scanlator.bank_url
    assert_equal 'https://telegram.me/team', @scanlator.extra_url
  end

  test 'stores blank links as nil' do
    @scanlator.bank_url = '  '

    assert_nil @scanlator.bank_url
  end

  test 'accepts donation links on known services, including their subdomains' do
    %w[
      https://send.monobank.ua/jar/abc
      https://www.privat24.ua/send/abc
      https://next.privat24.ua/send/abc
      https://donatello.to/team
      https://www.buymeacoffee.com/team
      https://ko-fi.com/team
    ].each do |url|
      @scanlator.bank_url = url

      assert_predicate @scanlator, :valid?, "#{url}: #{@scanlator.errors.full_messages.to_sentence}"
    end
  end

  test 'rejects a donation link outside the known services and lists them' do
    @scanlator.bank_url = 'https://t.me/c/1614732671/498'

    assert_not @scanlator.valid?
    assert_includes @scanlator.errors[:bank_url].first, 'monobank'
    assert_includes @scanlator.errors[:bank_url].first, 'Patreon'
  end

  test 'rejects Boosty as a donation service' do
    @scanlator.bank_url = 'https://boosty.to/team'

    assert_not @scanlator.valid?
    assert_not_includes @scanlator.errors[:bank_url].first, 'Boosty'
  end

  test 'rejects Russian domains with a dedicated message' do
    russian_domain = I18n.t('activerecord.errors.models.scanlator.attributes.extra_url.russian_domain')

    %w[https://vk.ru/team https://site.su https://сайт.рф https://xn--80aswg.xn--p1ai https://clck.ru/abc].each do |url|
      @scanlator.extra_url = url

      assert_not @scanlator.valid?, url
      assert_equal [russian_domain], @scanlator.errors[:extra_url], url
    end
  end

  test 'rejects a Cyrillic hostname that cannot be linked' do
    @scanlator.extra_url = 'https://приклад.укр'

    assert_not @scanlator.valid?
    assert_equal [I18n.t('activerecord.errors.models.scanlator.attributes.extra_url.unsafe')],
                 @scanlator.errors[:extra_url]
  end

  test 'rejects lookalike hosts that only end with a service name' do
    @scanlator.bank_url = 'https://fakemonobank.ua/jar/abc'

    assert_not @scanlator.valid?
  end

  test 'rejects an email that would become a user@host URL' do
    @scanlator.extra_url = 'aleks.grin08@gmail.com'

    assert_not @scanlator.valid?
    assert_equal [I18n.t('activerecord.errors.models.scanlator.attributes.extra_url.unsafe')],
                 @scanlator.errors[:extra_url]
  end

  test 'rejects IP addresses, shorteners, bare words and non-web schemes' do
    %w[https://192.168.0.1/pay https://bit.ly/abc team javascript:alert(1) ftp://example.com/x].each do |url|
      @scanlator.extra_url = url

      assert_not @scanlator.valid?, url
    end
  end

  test 'accepts ordinary community links with non-ASCII paths' do
    @scanlator.extra_url = 'https://manga.in.ua/xfsearch/perek/кафка/'

    assert_predicate @scanlator, :valid?, @scanlator.errors.full_messages.to_sentence
    assert_equal 'https://manga.in.ua/xfsearch/perek/%D0%BA%D0%B0%D1%84%D0%BA%D0%B0/', @scanlator.extra_link_url
  end

  test 'does not block unrelated saves of a team with an old invalid link' do
    save_without_validation(extra_url: 'aleks.grin08@gmail.com')

    assert @scanlator.reload.update(title: 'Renamed team')
  end

  test 'hides old invalid links from readers' do
    save_without_validation(bank_url: 'https://t.me/c/1614732671/498', extra_url: 'aleks.grin08@gmail.com')

    assert_nil @scanlator.donation_url
    assert_nil @scanlator.donation_service
    assert_nil @scanlator.extra_link_url
  end

  test 'serves old plain http links over https' do
    assert_equal 'https://send.monobank.ua/jar/abc', ScanlatorLinks.safe_uri('http://send.monobank.ua/jar/abc').to_s
  end

  private

  def save_without_validation(**links)
    @scanlator.assign_attributes(links)
    @scanlator.save!(validate: false)
  end
end
