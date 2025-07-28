# frozen_string_literal: true

namespace :test do
  desc 'Test Devise authentication and session storage'
  task auth: :environment do
    puts '=== Testing Devise Authentication ==='

    # Test 1: Check if we can find a user
    user = User.first
    if user
      puts "✅ Found user: #{user.email} (ID: #{user.id})"
    else
      puts '❌ No users found in database'
      return
    end

    # Test 2: Check if user can authenticate
    if user.valid_password?('password') # assuming default password
      puts '✅ User can authenticate with password'
    else
      puts "⚠️  User cannot authenticate with 'password' - might need different password"
    end

    # Test 3: Check Devise configuration
    puts "\n=== Devise Configuration ==="
    puts "Devise modules: #{User.devise_modules.join(', ')}"
    puts "Session store: #{Rails.application.config.session_store}"
    puts "Secret key base present: #{Rails.application.secret_key_base.present?}"

    # Test 4: Check session store configuration
    puts "\n=== Session Store Configuration ==="
    session_store = Rails.application.config.session_store
    if session_store.is_a?(Class)
      puts "Session store class: #{session_store}"
    else
      puts "Session store: #{session_store}"
    end

    # Test 5: Test session creation
    puts "\n=== Testing Session Creation ==="
    begin
      # Create a more realistic request environment
      env = {
        'HTTP_HOST' => 'localhost:3000',
        'REQUEST_METHOD' => 'GET',
        'rack.input' => StringIO.new,
        'action_dispatch.request_id' => 'test-auth-request',
        'action_dispatch.secret_key_base' => Rails.application.secret_key_base,
        'action_dispatch.signed_cookie_salt' => 'signed cookie',
        'action_dispatch.encrypted_cookie_salt' => 'encrypted cookie',
        'action_dispatch.encrypted_signed_cookie_salt' => 'signed encrypted cookie'
      }

      # Create request with proper middleware stack
      app = Rails.application
      request = ActionDispatch::TestRequest.create(env)

      # Test if we can access session
      puts '✅ Test request created successfully'
      puts "Request class: #{request.class}"

      # Try to access session through the application
      status, headers, body = app.call(env)
      puts "✅ Application call successful - Status: #{status}"

      # Check if session cookie was set
      if headers['Set-Cookie']
        puts '✅ Session cookie set in response'
        puts "Cookie: #{headers['Set-Cookie']}"
      else
        puts '⚠️  No session cookie set in response'
      end
    rescue StandardError => e
      puts "❌ Session test failed: #{e.message}"
      puts "Error class: #{e.class}"
      puts "Backtrace: #{e.backtrace.first(3).join("\n  ")}"
    end

    # Test 6: Check Warden configuration
    puts "\n=== Warden Configuration ==="
    begin
      warden = Warden::Manager.new(nil)
      puts '✅ Warden::Manager can be instantiated'
    rescue StandardError => e
      puts "❌ Warden::Manager instantiation failed: #{e.message}"
    end

    puts "\n=== Test Complete ==="
  end

  desc 'Test what a proper authenticated session should contain'
  task session_debug: :environment do
    puts '=== Testing Session Contents ==='

    # Test 1: Check current session structure
    puts "\n=== Current Session Structure ==="
    puts "Session store: #{Rails.application.config.session_store}"

    # Test 2: Create a test session with Warden data
    puts "\n=== Testing Warden Session Data ==="
    begin
      # Create a test environment
      env = {
        'HTTP_HOST' => 'localhost:3000',
        'REQUEST_METHOD' => 'GET',
        'rack.input' => StringIO.new,
        'action_dispatch.request_id' => 'test-session-debug',
        'action_dispatch.secret_key_base' => Rails.application.secret_key_base,
        'action_dispatch.signed_cookie_salt' => 'signed cookie',
        'action_dispatch.encrypted_cookie_salt' => 'encrypted cookie',
        'action_dispatch.encrypted_signed_cookie_salt' => 'signed encrypted cookie'
      }

      app = Rails.application
      status, headers, body = app.call(env)

      # Extract session cookie
      if headers['Set-Cookie']
        session_cookie = headers['Set-Cookie'].split(';').first
        puts "✅ Session cookie created: #{session_cookie[0..50]}..."

        # Try to decrypt and inspect
        cookie_value = session_cookie.split('=').last
        puts "Cookie value length: #{cookie_value.length}"

        # Test decryption
        begin
          decoded = Rails.application.message_verifier('_tanooki_session').verify(cookie_value)
          puts '✅ Cookie decrypted successfully'
          puts "Decoded keys: #{decoded.keys.join(', ')}"
          puts "Session ID: #{decoded['session_id']}"
          puts "Has warden data: #{decoded.key?('warden')}"
          puts "Warden data: #{decoded['warden']}" if decoded.key?('warden')
        rescue StandardError => e
          puts "❌ Cookie decryption failed: #{e.message}"
        end
      else
        puts '❌ No session cookie created'
      end
    rescue StandardError => e
      puts "❌ Session test failed: #{e.message}"
    end

    # Test 3: Check what Warden should store
    puts "\n=== Warden Session Structure ==="
    puts 'Warden typically stores user ID in session[:warden]'
    puts 'Expected format: session[:warden] = { user: { id: user_id, ... } }'

    puts "\n=== Test Complete ==="
  end

  desc 'Test authentication flow and session storage'
  task auth_flow: :environment do
    puts '=== Testing Authentication Flow ==='

    # Test 1: Find a user
    user = User.first
    if user.nil?
      puts '❌ No users found in database'
      return
    end
    puts "✅ Found user: #{user.email} (ID: #{user.id})"

    # Test 2: Check if user can authenticate
    if user.valid_password?('password')
      puts '✅ User can authenticate with password'
    else
      puts "⚠️  User cannot authenticate with 'password' - trying different passwords..."
      # Try some common passwords
      %w[123456 password123 admin test].each do |pwd|
        if user.valid_password?(pwd)
          puts "✅ User can authenticate with '#{pwd}'"
          break
        end
      end
    end

    # Test 3: Check Warden configuration
    puts "\n=== Warden Configuration ==="
    puts "Warden::Manager: #{Warden::Manager}"
    puts "Warden strategies: #{Warden::Strategies}"

    # Test 4: Check session store configuration
    puts "\n=== Session Store Configuration ==="
    session_store = Rails.application.config.session_store
    puts "Session store: #{session_store}"
    puts "Session store class: #{session_store.class}"

    # Test 5: Check if Warden is properly configured
    puts "\n=== Warden Setup ==="
    begin
      # Check if Warden is in the middleware stack
      middleware_stack = Rails.application.middleware
      warden_middleware = middleware_stack.find { |m| m.klass == Warden::Manager }
      if warden_middleware
        puts '✅ Warden::Manager found in middleware stack'
      else
        puts '❌ Warden::Manager NOT found in middleware stack'
      end

      # Check session middleware
      session_middleware = middleware_stack.find { |m| m.klass == ActionDispatch::Session::CookieStore }
      if session_middleware
        puts '✅ ActionDispatch::Session::CookieStore found in middleware stack'
      else
        puts '❌ ActionDispatch::Session::CookieStore NOT found in middleware stack'
      end

      # Check middleware order
      puts "\n=== Middleware Order ==="
      middleware_stack.each_with_index do |middleware, index|
        if [Warden::Manager, ActionDispatch::Session::CookieStore].include?(middleware.klass)
          puts "#{index}: #{middleware.klass}"
        end
      end
    rescue StandardError => e
      puts "❌ Error checking middleware: #{e.message}"
    end

    puts "\n=== Test Complete ==="
  end

  desc 'Test actual authentication process'
  task login_test: :environment do
    puts '=== Testing Actual Login Process ==='

    # Test 1: Find a user
    user = User.first
    if user.nil?
      puts '❌ No users found in database'
      return
    end
    puts "✅ Found user: #{user.email} (ID: #{user.id})"

    # Test 2: Try to authenticate the user
    puts "\n=== Testing Authentication ==="
    begin
      # Create a test request to the login page
      env = {
        'HTTP_HOST' => 'localhost:3000',
        'REQUEST_METHOD' => 'POST',
        'PATH_INFO' => '/login',
        'rack.input' => StringIO.new("user[email]=#{user.email}&user[password]=password"),
        'action_dispatch.request_id' => 'test-login',
        'action_dispatch.secret_key_base' => Rails.application.secret_key_base,
        'action_dispatch.signed_cookie_salt' => 'signed cookie',
        'action_dispatch.encrypted_cookie_salt' => 'encrypted cookie',
        'action_dispatch.encrypted_signed_cookie_salt' => 'signed encrypted cookie',
        'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
      }

      app = Rails.application
      status, headers, body = app.call(env)

      puts "Login response status: #{status}"

      # Check if session cookie was set
      if headers['Set-Cookie']
        puts '✅ Session cookie set in response'
        session_cookies = Array(headers['Set-Cookie']).select { |c| c.include?('_tanooki_session') }
        puts "Session cookie: #{session_cookies.first.split(';').first}" if session_cookies.any?
      else
        puts '❌ No session cookie set in response'
      end
    rescue StandardError => e
      puts "❌ Login test failed: #{e.message}"
      puts "Error class: #{e.class}"
    end

    puts "\n=== Test Complete ==="
  end
end
