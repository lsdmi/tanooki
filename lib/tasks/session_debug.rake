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
  end

  desc 'Test session logging by making a test request'
  task test_logging: :environment do
    puts '=== Testing Session Logging ==='

    # Create a test request to trigger logging
    begin
      # Create a test environment
      env = {
        'HTTP_HOST' => 'localhost:3000',
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/',
        'rack.input' => StringIO.new,
        'action_dispatch.request_id' => 'test-session-logging',
        'action_dispatch.secret_key_base' => Rails.application.secret_key_base,
        'action_dispatch.signed_cookie_salt' => 'signed cookie',
        'action_dispatch.encrypted_cookie_salt' => 'encrypted cookie',
        'action_dispatch.encrypted_signed_cookie_salt' => 'signed encrypted cookie'
      }

      app = Rails.application
      status, headers, body = app.call(env)

      puts "✅ Test request completed - Status: #{status}"
      puts '✅ Check your logs for SESSION_ENTRY_CHECK and SESSION_EXIT_CHECK messages'
      puts '✅ Look for MIDDLEWARE_ENTRY and MIDDLEWARE_EXIT messages'
      puts '✅ Look for WARDEN_ENTRY and WARDEN_EXIT messages'

      if headers['Set-Cookie']
        puts '✅ Session cookie was set in response'
      else
        puts '⚠️  No session cookie set in response'
      end
    rescue StandardError => e
      puts "❌ Test request failed: #{e.message}"
      puts "Error class: #{e.class}"
    end
  end

  desc 'Monitor session logs in real-time'
  task monitor: :environment do
    puts '=== Session Log Monitor ==='
    puts 'This will show session-related log messages in real-time.'
    puts 'Press Ctrl+C to stop monitoring.'
    puts ''

    # This is a simple log monitoring approach
    # In production, you might want to use a more sophisticated log monitoring tool

    log_file = Rails.env.production? ? 'log/production.log' : 'log/development.log'

    if File.exist?(log_file)
      puts "Monitoring log file: #{log_file}"
      puts 'Looking for session-related messages...'
      puts ''

      # Simple log tailing (this is basic - consider using a proper log monitoring tool)
      begin
        File.open(log_file, 'r') do |file|
          file.seek(0, IO::SEEK_END)

          loop do
            if line = file.gets
              if line.include?('SESSION_ENTRY_CHECK') ||
                 line.include?('SESSION_EXIT_CHECK') ||
                 line.include?('MIDDLEWARE_ENTRY') ||
                 line.include?('MIDDLEWARE_EXIT') ||
                 line.include?('WARDEN_ENTRY') ||
                 line.include?('WARDEN_EXIT') ||
                 line.include?('COOKIE_ENTRY') ||
                 line.include?('COOKIE_EXIT')
                puts line.strip
              end
            else
              sleep 0.1
            end
          end
        end
      rescue Interrupt
        puts "\nMonitoring stopped."
      end
    else
      puts "❌ Log file not found: #{log_file}"
      puts 'Make sure the application is running and generating logs.'
    end
  end

  desc 'Show recent session-related log entries'
  task recent: :environment do
    puts '=== Recent Session Log Entries ==='

    log_file = Rails.env.production? ? 'log/production.log' : 'log/development.log'

    if File.exist?(log_file)
      puts "Reading recent entries from: #{log_file}"
      puts ''

      # Read last 100 lines and filter for session-related messages
      lines = File.readlines(log_file).last(100)
      session_lines = lines.select do |line|
        line.include?('SESSION_ENTRY_CHECK') ||
          line.include?('SESSION_EXIT_CHECK') ||
          line.include?('MIDDLEWARE_ENTRY') ||
          line.include?('MIDDLEWARE_EXIT') ||
          line.include?('WARDEN_ENTRY') ||
          line.include?('WARDEN_EXIT') ||
          line.include?('COOKIE_ENTRY') ||
          line.include?('COOKIE_EXIT')
      end

      if session_lines.any?
        session_lines.each { |line| puts line.strip }
      else
        puts 'No recent session-related log entries found.'
        puts 'Try making some requests to the application first.'
      end
    else
      puts "❌ Log file not found: #{log_file}"
    end
  end
end
