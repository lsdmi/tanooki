# frozen_string_literal: true

namespace :production do
  desc 'Enable session debugging in production temporarily'
  task enable_debug: :environment do
    puts '=== Production Session Debugging ==='
  end

  desc 'Check production session configuration'
  task check_session: :environment do
    puts '=== Production Session Configuration ==='
    puts "Environment: #{Rails.env}"
    puts "Session Store: #{Rails.application.config.session_store}"
    puts "Secret Key Base: #{Rails.application.secret_key_base ? 'Set' : 'NOT SET'}"
    puts "Force SSL: #{Rails.application.config.force_ssl}"

    # Check session store configuration
    if Rails.application.config.session_store == ActionDispatch::Session::CookieStore
      puts 'Session Key: _tanooki_session'
      puts "Cookie Domain: #{Rails.application.config.session_store == ActionDispatch::Session::CookieStore ? 'Default' : 'Custom'}"
    end

    puts ''
    puts '=== Devise Configuration ==='
    puts "Rememberable: #{User.devise_modules.include?(:rememberable)}"
    puts "Timeoutable: #{User.devise_modules.include?(:timeoutable)}"
    puts "Confirmable: #{User.devise_modules.include?(:confirmable)}"

    puts "Timeout Duration: #{Devise.timeout_in}" if User.devise_modules.include?(:timeoutable)
  end

  desc 'Test production cookie encryption'
  task test_cookies: :environment do
    puts '=== Production Cookie Test ==='

    begin
      # Test basic cookie functionality
      test_data = { 'user_id' => 123, 'email' => 'test@example.com', 'timestamp' => Time.current.to_i }

      env = {
        'HTTP_HOST' => 'localhost:3000',
        'REQUEST_METHOD' => 'GET',
        'rack.input' => StringIO.new,
        'action_dispatch.request_id' => 'test-request-id'
      }

      request = ActionDispatch::TestRequest.create(env)
      cookie_jar = request.cookie_jar

      # Test encrypted cookies (what Rails uses for sessions)
      cookie_jar.encrypted['test_session'] = test_data
      encrypted_cookie = cookie_jar['test_session']

      puts '✓ Cookie encryption works'
      puts "  Encrypted cookie length: #{encrypted_cookie.length}"

      # Test decryption
      decrypted = cookie_jar.encrypted['test_session']
      if decrypted == test_data
        puts '✓ Cookie decryption works'
      else
        puts '✗ Cookie decryption failed'
        puts "  Expected: #{test_data}"
        puts "  Got: #{decrypted}"
      end
    rescue StandardError => e
      puts "✗ Cookie test failed: #{e.message}"
      puts "  Error class: #{e.class}"
    end
  end

  desc 'Monitor production logs for session issues'
  task monitor_logs: :environment do
    puts '=== Production Log Monitoring ==='
    puts 'To monitor session-related logs in production:'
    puts ''
    puts '1. Enable debugging:'
    puts ''
    puts '2. Monitor logs:'
    puts "   tail -f log/production.log | grep -E '(COOKIE_DEBUG|SESSION_DEBUG|MIDDLEWARE_DEBUG|Error|Exception)'"
    puts ''
    puts '3. Look for these patterns:'
    puts "   - 'Cookie present but user not authenticated'"
    puts "   - 'Cookie decryption failed'"
    puts "   - 'Auth failure'"
    puts "   - 'User authenticated' / 'User logging out'"
  end
end
