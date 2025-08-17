# frozen_string_literal: true

if defined?(Bullet)
  Rails.application.config.after_initialize do
    Bullet.enable = true

    # Enable notifications to see warnings
    Bullet.console = true                  # Browser console logging
    Bullet.add_footer = true               # Footer display on page
  end
end
