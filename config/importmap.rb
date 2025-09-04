# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin 'flowbite', to: 'https://cdn.jsdelivr.net/npm/flowbite@3.1.2/dist/flowbite.turbo.min.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers', preload: false
pin '@rails/actiontext', to: 'actiontext.js'
pin 'slim-select', to: 'https://cdnjs.cloudflare.com/ajax/libs/slim-select/2.8.2/slimselect.es.min.js'
pin 'sweetalert2', to: 'https://ga.jspm.io/npm:sweetalert2@11.14.0/dist/sweetalert2.all.js'
pin '@rails/actioncable', to: 'actioncable.esm.js'
pin_all_from 'app/javascript/channels', under: 'channels', preload: true

# Explicit pins for Action Cable files
pin 'channels/consumer', preload: true
pin 'channels/chat_channel', preload: true
pin 'channels/index', preload: true
