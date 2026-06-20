# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin 'turbo_transitions', preload: true
pin 'adult_content_disclaimer'
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin 'flowbite', to: 'https://cdn.jsdelivr.net/npm/flowbite@3.1.2/dist/flowbite.turbo.min.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers', preload: false
pin 'controllers/chapters_accordion_controller', preload: false
pin 'controllers/note_reference_controller', preload: false
pin 'controllers/sweet_alert_controller', preload: false
pin 'slim-select', to: 'https://cdnjs.cloudflare.com/ajax/libs/slim-select/2.8.2/slimselect.es.min.js'
pin 'sweetalert2', to: 'https://ga.jspm.io/npm:sweetalert2@11.14.0/dist/sweetalert2.all.js'
pin '@rails/actioncable', to: 'actioncable.esm.js'
pin_all_from 'app/javascript/channels', under: 'channels', preload: true

# Explicit pins for Action Cable files
pin 'channels/consumer', preload: true
pin 'channels/chat_channel', preload: true
pin 'channels/index', preload: true

# Translation request Stimulus helpers
pin_all_from 'app/javascript/translation_requests', under: 'translation_requests'
pin 'reader_preferences', preload: false
pin 'safe_logo_src', preload: false
pin 'mode_toggler', preload: false
pin 'cookie_consent', preload: true
pin 'font_toggler', preload: false
pin 'adblock_detect', preload: false

# Chapter schedule date (UA calendar; native type=date is OS-locale bound)
pin 'flatpickr', to: 'https://esm.sh/flatpickr@4.6.13', preload: false
