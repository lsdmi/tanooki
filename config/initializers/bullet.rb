# frozen_string_literal: true

if defined?(Bullet)
  Rails.application.config.after_initialize do
    Bullet.enable = true

    if Rails.env.development?
      Bullet.console = true
      Bullet.add_footer = true
    end

    # Fail the suite on N+1 and unused eager loads. Intentional skips go in config/bullet_safelist.rb.
    if Rails.env.test?
      Bullet.raise = true
      require Rails.root.join('config/bullet_safelist')
    end
  end
end
