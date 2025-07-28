# frozen_string_literal: true

Rails.application.config.session_store :cookie_store,
                                       key: '_tanooki_session',
                                       expire_after: 30.days,
                                       secure: Rails.env.production?,
                                       httponly: true,
                                       same_site: :lax
