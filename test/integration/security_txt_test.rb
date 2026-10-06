# frozen_string_literal: true

require 'test_helper'

class SecurityTxtTest < ActiveSupport::TestCase
  SECURITY_TXT = Rails.public_path.join('.well-known/security.txt')

  test 'lists an abuse contact' do
    assert_includes SECURITY_TXT.read.lines(chomp: true), 'Contact: mailto:support@baka.in.ua'
  end

  test 'has not expired or come close to it' do
    expires = Time.iso8601(SECURITY_TXT.read[/^Expires: (.+)$/, 1])

    assert_operator expires, :>, 30.days.from_now, 'Renew the Expires date in public/.well-known/security.txt'
  end
end
