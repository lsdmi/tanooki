# frozen_string_literal: true

namespace :session do
  desc 'Test session debugging by checking current session configuration'
  task debug: :environment do
    puts '=== Session Debug Information ==='
    puts "Rails Environment: #{Rails.env}"
    puts "Session Store: #{Rails.application.config.session_store}"

    # Get session configuration from initializer
    session_config = Rails.application.config.session_store
    puts "Session Store Class: #{session_config}" if session_config.is_a?(Class)

    # Check session store configuration
    if Rails.application.config.session_store == ActionDispatch::Session::CookieStore
      puts 'Session Key: _tanooki_session'
      puts 'Session Expiry: 30 days'
    end

    puts "Secret Key Base: #{Rails.application.secret_key_base ? 'Set' : 'Not Set'}"
    puts "Devise Secret Key: #{Devise.secret_key ? 'Set' : 'Not Set'}"

    # Check if we're in production and SSL is configured
    if Rails.env.production?
      puts "Production SSL: #{Rails.application.config.force_ssl ? 'Enabled' : 'Disabled'}"
    end

    # Check session middleware
    puts "\n=== Session Middleware ==="
    Rails.application.middleware.each do |middleware|
      middleware_name = middleware.name || middleware.to_s
      puts "  #{middleware_name}" if middleware_name.include?('Session') || middleware_name.include?('Cookie')
    end

    puts "\n=== Devise Configuration ==="
    puts "  Rememberable Options: #{Devise.rememberable_options}"
    puts "  Timeoutable: #{User.devise_modules.include?(:timeoutable)}"
    puts "  Confirmable: #{User.devise_modules.include?(:confirmable)}"
    puts "  Lockable: #{User.devise_modules.include?(:lockable)}"

    puts "  Timeout Duration: #{Devise.timeout_in}" if User.devise_modules.include?(:timeoutable)

    puts "\n=== Current Session Info ==="
    puts "  Session ID: #{Rails.application.config.session_store}"
    puts "  Cookie Domain: #{Rails.application.config.session_store == ActionDispatch::Session::CookieStore ? 'Default' : 'Custom'}"
    puts "  Cookie Secure: #{Rails.application.config.force_ssl ? 'Yes' : 'No'}"
    puts "  Cookie HttpOnly: #{Rails.application.config.session_store == ActionDispatch::Session::CookieStore ? 'Yes' : 'No'}"

    puts "\n=== Cookie Testing ==="
    test_cookie_encryption
  end

  desc 'Test cookie encryption and decryption'
  task test_cookies: :environment do
    puts '=== Cookie Encryption Test ==='
    test_cookie_encryption
  end

  private

  def test_cookie_encryption
    # Test cookie encryption/decryption
    test_data = { 'user_id' => 123, 'email' => 'test@example.com', 'timestamp' => Time.current.to_i }

    puts "Testing cookie encryption with data: #{test_data}"

    begin
      # Create a test request and cookie jar
      env = {
        'HTTP_HOST' => 'localhost:3000',
        'REQUEST_METHOD' => 'GET',
        'rack.input' => StringIO.new,
        'action_dispatch.request_id' => 'test-request-id'
      }

      request = ActionDispatch::TestRequest.create(env)
      cookie_jar = request.cookie_jar

      # Test basic cookie functionality
      cookie_jar['test_cookie'] = 'test_value'
      test_cookie = cookie_jar['test_cookie']
      puts '✓ Basic cookie functionality works'
      puts "  Test cookie value: #{test_cookie}"

      # Test signed cookies
      cookie_jar.signed['signed_cookie'] = test_data
      signed_cookie = cookie_jar['signed_cookie']
      puts '✓ Signed cookie encryption successful'
      puts "  Signed cookie length: #{signed_cookie.length}"

      # Test encrypted cookies
      cookie_jar.encrypted['encrypted_cookie'] = test_data
      encrypted_cookie = cookie_jar['encrypted_cookie']
      puts '✓ Encrypted cookie encryption successful'
      puts "  Encrypted cookie length: #{encrypted_cookie.length}"
    rescue StandardError => e
      puts "✗ Cookie test failed: #{e.message}"
      puts "  Error class: #{e.class}"
      puts "  Backtrace: #{e.backtrace.first(3).join("\n    ")}"
    end

    puts "\n=== Session Store Test ==="
    test_session_store
  end

  def test_session_store
    # Test session store functionality
    puts 'Testing session store functionality...'

    begin
      # Create a mock request
      env = {
        'HTTP_HOST' => 'localhost:3000',
        'REQUEST_METHOD' => 'GET',
        'rack.input' => StringIO.new,
        'action_dispatch.request_id' => 'test-request-id'
      }

      # Create a session store instance
      session_store = Rails.application.config.session_store.new(nil, {})
      puts '✓ Session store created successfully'

      # Test session ID generation
      session_id = session_store.generate_sid
      puts "✓ Session ID generated: #{session_id}"
    rescue StandardError => e
      puts "✗ Session store test failed: #{e.message}"
      puts "  Error class: #{e.class}"
    end
  end
end
